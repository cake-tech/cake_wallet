import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/everstake/ethereum_transaction_validator.dart";
import "package:cake_wallet/core/everstake/everstake_service.dart";
import "package:cake_wallet/core/everstake/exceptions.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:meta/meta.dart";
import "package:mobx/mobx.dart" show ReactionDisposer, reaction;
import "package:shared_preferences/shared_preferences.dart";

part "ethereum_staking_event.dart";
part "ethereum_staking_state.dart";

class EthereumStakingBloc extends Bloc<EthereumStakingEvent, EthereumStakingState> {
  EthereumStakingBloc({
    required WalletBase wallet,
    required SettingsStore settingsStore,
    required EVM evm,
    required EverstakeService service,
    required EverstakeEthereumTransactionValidator validator,
  })  : _wallet = wallet,
        _settingsStore = settingsStore,
        _evm = evm,
        _service = service,
        _validator = validator,
        _address = wallet.walletAddresses.address,
        super(const EthereumStakingLoading(null)) {
    // one handler so droppable() ignores events while another is in flight
    on<EthereumStakingEvent>(
      (event, emit) => switch (event) {
        StakingDataRequested() => _onStakingDataRequested(emit),
        TransactionRequested() => _onTransactionRequested(event, emit),
        TransactionConfirmed() => _onTransactionConfirmed(event, emit),
      },
      transformer: droppable(),
    );

    add(const StakingDataRequested());

    _walletBalanceReaction = reaction((_) => _walletBalance, (_) {
      if (state is! EthereumStakingPrepared) {
        add(const StakingDataRequested());
      }
    });
  }

  static const _allowedInterchangeNum = 5;
  static const _mainnetChainId = 1;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final EVM _evm;
  final EverstakeService _service;
  final EverstakeEthereumTransactionValidator _validator;
  final String _address;
  late final ReactionDisposer _walletBalanceReaction;

  String get walletName => _wallet.name;

  String get address => _address;

  Money get _walletBalance =>
      _wallet.balance[CryptoCurrency.eth]?.available ?? Money.zero(CryptoCurrency.eth);

  TransactionPriority? get _priority =>
      _settingsStore.getPriority(_wallet.type, chainId: _mainnetChainId);

  @override
  Future<void> close() {
    _walletBalanceReaction();
    return super.close();
  }

  Future<void> _onStakingDataRequested(Emitter<EthereumStakingState> emit) async {
    emit(EthereumStakingLoading(state.data));
    try {
      final data = await _loadData();
      emit(EthereumStakingReady(data));
    } catch (error) {
      emit(EthereumStakingFailure(state.data, _errorMessage(error)));
    }
  }

  Future<void> _onTransactionRequested(
    TransactionRequested event,
    Emitter<EthereumStakingState> emit,
  ) async {
    final data = state.data;
    if (data == null) {
      return;
    }

    try {
      await _prepare(event, data, emit);
    } catch (error) {
      emit(EthereumStakingFailure(data, _errorMessage(error)));
    }
  }

  Future<void> _onTransactionConfirmed(
    TransactionConfirmed event,
    Emitter<EthereumStakingState> emit,
  ) async {
    if (state case final EthereumStakingPrepared prepared
        when identical(prepared.operation, event.operation)) {
      emit(EthereumStakingSubmitting(prepared.data, prepared.operation));
      try {
        await prepared.operation.transaction.commit();
      } catch (error) {
        emit(EthereumStakingFailure(prepared.data, _errorMessage(error)));
        return;
      }

      try {
        final sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences.setString(
          PreferencesKey.backgroundSyncLastTrigger(_wallet.name),
          DateTime.now().add(const Duration(minutes: 1)).toIso8601String(),
        );
      } catch (error) {
        printV("Failed to update background sync after staking: $error");
      }
      emit(EthereumStakingSubmitted(prepared.data, prepared.operation));

      // like Send flow, record the pending transaction here because EVM sync can take a while
      final transaction = prepared.operation.transaction;
      _wallet.transactionHistory.addOne(
        _evm.getTransactionInfo(
          id: transaction.evmTxHashFromRawHex!,
          height: 0,
          amount: transaction.amount,
          fee: transaction.fee,
          tokenSymbol: CryptoCurrency.eth.title,
          direction: TransactionDirection.outgoing,
          isPending: true,
          date: DateTime.now(),
          confirmations: 0,
          chainId: _mainnetChainId,
        ),
      );

      Future.delayed(const Duration(seconds: 4), () async {
        try {
          await Future.wait([
            _wallet.updateTransactionsHistory(),
            _wallet.updateBalance()!,
          ]);
        } catch (error) {
          printV("Failed to update wallet after staking: $error");
        }
      });
    }
  }

  Future<EthereumStakingData> _loadData() async {
    final (minimum, fee, balances, rewards, withdrawal, apr, activationTime, totalRewards) = await (
      _service.getEthereumMinStakeAmount(),
      _service.getEthereumFee(),
      _service.getEthereumUserBalances(_address),
      _service.getEthereumRestakedRewards(_address),
      _service.getEthereumWithdrawRequest(_address),
      _optional(_service.getEthereumApr()),
      _optional(_service.getEthereumActivationTime()),
      _optional(_service.getEthereumTotalRewards(_address)),
    ).wait;
    return EthereumStakingData(
      minStakeAmount: minimum,
      poolFee: fee,
      balances: balances,
      restakedRewards: rewards,
      withdrawRequest: withdrawal,
      walletBalance: _walletBalance,
      apr: apr,
      activationTime: activationTime,
      totalRewards: totalRewards,
    );
  }

  Future<T?> _optional<T>(Future<T> request) async {
    try {
      return await request;
    } catch (error) {
      printV("Optional Everstake request failed: $error");
      return null;
    }
  }

  Future<void> _prepare(
    TransactionRequested event,
    EthereumStakingData data,
    Emitter<EthereumStakingState> emit,
  ) async {
    emit(EthereumStakingPreparing(data));

    final (action, amount) = switch (event) {
      StakeRequested(:final amount) => (EthereumStakingAction.stake, amount),
      MaxStakeRequested() => (EthereumStakingAction.stake, await _maxStakeAmount(data)),
      UnstakeRequested(:final amount) => (EthereumStakingAction.unstake, amount),
      PendingUnstakeRequested(:final amount) => (EthereumStakingAction.unstakePending, amount),
      WithdrawalClaimRequested() => (
          EthereumStakingAction.claimWithdrawal,
          data.withdrawRequest.requested
        ),
    };
    if (amount.sign <= 0) {
      throw const EverstakeNonPositiveAmountException();
    }

    final EverstakeEthereumTransaction transaction;
    Money? instantUnstakeAmount;
    switch (event) {
      case StakeRequested() || MaxStakeRequested():
        if (amount < data.minStakeAmount) {
          throw const EverstakeBelowMinimumException();
        }
        if (amount > _walletBalance) {
          throw const EverstakeInsufficientBalanceException();
        }
        transaction = await _prepareStake(amount);
      case UnstakeRequested():
        if (amount > data.balances.autocompoundBalance) {
          throw const EverstakeInsufficientBalanceException();
        }
        instantUnstakeAmount = await _service.simulateEthereumUnstake(
          address: _address,
          amount: amount,
          allowedInterchangeNum: _allowedInterchangeNum,
        );
        transaction = await _service.prepareEthereumUnstake(
          address: _address,
          amount: amount,
          allowedInterchangeNum: _allowedInterchangeNum,
        );
        _validator.validateUnstake(
          transaction,
          address: _address,
          amount: amount,
          allowedInterchangeNum: _allowedInterchangeNum,
          source: EverstakeService.source,
        );
      case PendingUnstakeRequested():
        final remainder = data.balances.pendingBalance - amount;
        if (remainder.isNegative) {
          throw const EverstakeInsufficientBalanceException();
        }
        if (!remainder.isZero && remainder < data.minStakeAmount) {
          throw EverstakeRemainderBelowMinimumException(data.minStakeAmount);
        }
        transaction =
            await _service.prepareEthereumUnstakePending(address: _address, amount: amount);
        _validator.validateUnstakePending(transaction, address: _address, amount: amount);
      case WithdrawalClaimRequested():
        if (!data.canClaimWithdrawal) {
          throw const EverstakeWithdrawalNotReadyException();
        }
        transaction = await _service.prepareEthereumClaimWithdrawRequest(_address);
        _validator.validateClaimWithdrawRequest(transaction, address: _address);
    }

    final pending = await _signOnMainnet(transaction);

    emit(
      EthereumStakingPrepared(
        data,
        EthereumStakingOperation(
          action: action,
          amount: amount,
          transaction: pending,
          instantUnstakeAmount: instantUnstakeAmount,
        ),
      ),
    );
  }

  Future<EverstakeEthereumTransaction> _prepareStake(Money amount) async {
    final transaction = await _service.prepareEthereumStake(address: _address, amount: amount);
    _validator.validateStake(
      transaction,
      address: _address,
      amount: amount,
      source: EverstakeService.source,
    );
    return transaction;
  }

  Future<Money> _maxStakeAmount(EthereumStakingData data) async {
    final balance = _walletBalance;
    if (balance < data.minStakeAmount) {
      throw const EverstakeBelowMinimumException();
    }
    _checkMainnet();
    final stake = await _prepareStake(data.minStakeAmount);
    final fee = _checkFee(
      await _evm.estimateRawCallDataTransactionFee(
        _wallet,
        stake.to,
        stake.data,
        balance,
        _priority,
      ),
    );
    return balance - fee * BigInt.two; // add some buffer
  }

  Future<PendingTransaction> _signOnMainnet(EverstakeEthereumTransaction transaction) async {
    _checkMainnet();
    final pending = await _evm.createRawCallDataTransaction(
      _wallet,
      transaction.to,
      transaction.data,
      transaction.value,
      _priority,
      useBlinkProtection: _settingsStore.useBlinkProtection,
    );
    _checkFee(pending.fee);
    return pending;
  }

  void _checkMainnet() {
    if (_wallet.chainId != _mainnetChainId) {
      throw const EverstakeMainnetRequiredException();
    }
  }

  Money _checkFee(Money fee) {
    if (fee.isZero) {
      throw TransactionNoFeeException();
    }
    return fee;
  }

  String _errorMessage(Object error) => switch (error) {
        EverstakeNonPositiveAmountException() ||
        EverstakeBelowMinimumException() =>
          S.current.error_text_input_below_minimum_limit,
        EverstakeInsufficientBalanceException() => S.current.error_text_input_above_maximum_limit,
        EverstakeRemainderBelowMinimumException(:final minimum) =>
          S.current.staking_remainder_below_minimum(
            minimum.toLocalStringWithSymbol(
              locale: _settingsStore.languageCode,
            ),
          ),
        EverstakeWithdrawalNotReadyException() => S.current.staking_withdrawal_not_ready,
        EverstakeMainnetRequiredException() => S.current.staking_mainnet_only,
        EverstakeResponseException() ||
        EverstakeTransactionMismatchException() ||
        TimeoutException() =>
          S.current.provider_error("Everstake"),
        TransactionNoFeeException() => S.current.tx_zero_fee_exception,
        ParallelWaitError() => S.current.load_failed,
        _ => error.toString(),
      };
}
