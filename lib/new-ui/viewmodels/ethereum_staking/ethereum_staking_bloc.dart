import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/everstake/ethereum_transaction_validator.dart";
import "package:cake_wallet/core/everstake/everstake_service.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/wallet_base.dart";
import "package:meta/meta.dart";

part "ethereum_staking_event.dart";
part "ethereum_staking_state.dart";

class EthereumStakingBloc extends Bloc<EthereumStakingEvent, EthereumStakingState> {
  EthereumStakingBloc({
    required WalletBase wallet,
    required SettingsStore settingsStore,
    required EVM evm,
    required EverstakeService service,
    required EverstakeEthereumTransactionValidator validator,
    required String source,
  })  : _wallet = wallet,
        _settingsStore = settingsStore,
        _evm = evm,
        _service = service,
        _validator = validator,
        _source = source,
        _address = wallet.walletAddresses.address,
        super(const EthereumStakingLoading(null)) {
    // one handler so droppable() ignores events while another is in flight
    on<EthereumStakingEvent>(
      (event, emit) => switch (event) {
        LoadStakingData() => _onLoadStakingData(emit),
        PrepareTransaction() => _onPrepareTransaction(event, emit),
        SubmitTransaction() => _onSubmitTransaction(event, emit),
      },
      transformer: droppable(),
    );

    add(const LoadStakingData());
  }

  static const _allowedInterchangeNum = 0;
  static const _mainnetChainId = 1;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final EVM _evm;
  final EverstakeService _service;
  final EverstakeEthereumTransactionValidator _validator;
  final String _source;
  final String _address;

  Future<void> _onLoadStakingData(Emitter<EthereumStakingState> emit) async {
    emit(EthereumStakingLoading(state.data));
    try {
      final data = await _loadData();
      emit(EthereumStakingReady(data));
    } catch (error) {
      emit(EthereumStakingFailure(state.data, error));
    }
  }

  Future<void> _onPrepareTransaction(
    PrepareTransaction event,
    Emitter<EthereumStakingState> emit,
  ) async {
    final data = state.data;
    if (data == null) {
      return;
    }

    try {
      await _prepare(event, data, emit);
    } catch (error) {
      emit(EthereumStakingFailure(data, error));
    }
  }

  Future<void> _onSubmitTransaction(
    SubmitTransaction event,
    Emitter<EthereumStakingState> emit,
  ) async {
    if (state case final EthereumStakingPrepared prepared) {
      emit(EthereumStakingSubmitting(prepared.data, prepared.operation));
      try {
        await prepared.operation.transaction.commit();
      } catch (error) {
        emit(EthereumStakingFailure(prepared.data, error));
        return;
      }
      emit(EthereumStakingSubmitted(prepared.data, prepared.operation));
    }
  }

  Future<EthereumStakingData> _loadData() async {
    final (minimum, fee, balances, rewards, withdrawal) = await (
      _service.getEthereumMinStakeAmount(),
      _service.getEthereumFee(),
      _service.getEthereumUserBalances(_address),
      _service.getEthereumRestakedRewards(_address),
      _service.getEthereumWithdrawRequest(_address),
    ).wait;
    return EthereumStakingData(
      minStakeAmount: minimum,
      poolFee: fee,
      balances: balances,
      restakedRewards: rewards,
      withdrawRequest: withdrawal,
    );
  }

  Future<void> _prepare(
    PrepareTransaction event,
    EthereumStakingData data,
    Emitter<EthereumStakingState> emit,
  ) async {
    emit(EthereumStakingPreparing(data));

    final (action, amount) = switch (event) {
      PrepareStake(:final amount) => (EthereumStakingAction.stake, amount),
      PrepareUnstake(:final amount) => (EthereumStakingAction.unstake, amount),
      PreparePendingUnstake(:final amount) => (EthereumStakingAction.unstakePending, amount),
      PrepareWithdrawalClaim() => (
          EthereumStakingAction.claimWithdrawal,
          data.withdrawRequest.requested
        ),
    };
    if (amount.sign <= 0) {
      throw EthereumStakingError.nonPositiveAmount;
    }

    final EverstakeEthereumTransaction transaction;
    Money? instantUnstakeAmount;
    switch (event) {
      case PrepareStake():
        if (amount < data.minStakeAmount) {
          throw EthereumStakingError.belowMinimum;
        }
        transaction =
            await _service.prepareEthereumStake(address: _address, amount: amount, source: _source);
        _validator.validateStake(transaction, address: _address, amount: amount, source: _source);
      case PrepareUnstake():
        if (amount > data.balances.autocompoundBalance) {
          throw EthereumStakingError.exceedsBalance;
        }
        instantUnstakeAmount = await _service.simulateEthereumUnstake(
          address: _address,
          amount: amount,
          allowedInterchangeNum: _allowedInterchangeNum,
          source: _source,
        );
        transaction = await _service.prepareEthereumUnstake(
          address: _address,
          amount: amount,
          allowedInterchangeNum: _allowedInterchangeNum,
          source: _source,
        );
        _validator.validateUnstake(
          transaction,
          address: _address,
          amount: amount,
          allowedInterchangeNum: _allowedInterchangeNum,
          source: _source,
        );
      case PreparePendingUnstake():
        final remainder = data.balances.pendingBalance - amount;
        if (remainder.isNegative) {
          throw EthereumStakingError.exceedsBalance;
        }
        if (!remainder.isZero && remainder < data.minStakeAmount) {
          throw EthereumStakingError.remainderBelowMinimum;
        }
        transaction =
            await _service.prepareEthereumUnstakePending(address: _address, amount: amount);
        _validator.validateUnstakePending(transaction, address: _address, amount: amount);
      case PrepareWithdrawalClaim():
        if (!data.canClaimWithdrawal) {
          throw EthereumStakingError.withdrawalNotReady;
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

  // Everstake txs are mainnet-only; createRawCallDataTransaction signs on the selected chain.
  Future<PendingTransaction> _signOnMainnet(EverstakeEthereumTransaction transaction) {
    if (_wallet.chainId != _mainnetChainId) {
      throw EthereumStakingError.notMainnet;
    }

    return _evm.createRawCallDataTransaction(
      _wallet,
      transaction.to,
      transaction.data,
      transaction.value,
      _settingsStore.getPriority(_wallet.type, chainId: _mainnetChainId),
      useBlinkProtection: _settingsStore.useBlinkProtection,
    );
  }
}
