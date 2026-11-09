import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/morpho/morpho_exceptions.dart";
import "package:cake_wallet/core/morpho/morpho_service.dart";
import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:meta/meta.dart";
import "package:shared_preferences/shared_preferences.dart";

part "morpho_event.dart";
part "morpho_state.dart";

class MorphoBloc extends Bloc<MorphoEvent, MorphoState> {
  MorphoBloc({
    required WalletBase wallet,
    required SettingsStore settingsStore,
    required EVM evm,
    required MorphoVault vault,
    required MorphoService service,
  })  : _wallet = wallet,
        _settingsStore = settingsStore,
        _evm = evm,
        _vault = vault,
        _service = service,
        _address = wallet.walletAddresses.address,
        super(const MorphoLoading(null)) {
    on<YieldDataRequested>(_onYieldDataRequested, transformer: restartable());
    on<TransactionRequested>(_onTransactionRequested, transformer: droppable());
    on<TransactionConfirmed>(_onTransactionConfirmed, transformer: droppable());

    add(const YieldDataRequested());
  }

  static const _apiTimeout = Duration(seconds: 10);
  static const _receiptPollInterval = Duration(seconds: 3);

  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final EVM _evm;
  final MorphoVault _vault;
  final MorphoService _service;
  final String _address;

  String get walletName => _wallet.name;

  String get address => _address;

  Future<void> _onYieldDataRequested(
    YieldDataRequested event,
    Emitter<MorphoState> emit,
  ) async {
    if (state.isTransacting) {
      return;
    }
    emit(MorphoLoading(state.data));
    MorphoState next;
    try {
      next = MorphoReady(await _loadData());
    } catch (error) {
      next = MorphoFailure(state.data, _errorMessage(error));
    }
    if (state is MorphoLoading) {
      emit(next);
    }
  }

  Future<void> _onTransactionRequested(
    TransactionRequested event,
    Emitter<MorphoState> emit,
  ) async {
    final data = state.data;
    if (data == null || state.isTransacting) {
      return;
    }

    emit(MorphoPreparing(data));
    try {
      final operation = switch (event) {
        DepositRequested(:final amount) => await _prepareDeposit(amount),
        WithdrawRequested(:final amount) => await _prepareWithdraw(amount, data),
        WithdrawAllRequested() => await _prepareWithdraw(data.positionValue, data),
      };
      emit(MorphoPrepared(data, operation));
    } catch (error) {
      emit(MorphoFailure(data, _errorMessage(error)));
    }
  }

  Future<void> _onTransactionConfirmed(
    TransactionConfirmed event,
    Emitter<MorphoState> emit,
  ) async {
    if (state case MorphoPrepared(:final data, :final operation)
        when identical(operation, event.operation)) {
      emit(MorphoSubmitting(data, operation));
      try {
        _checkNetwork();
        await operation.transaction.commit();
        emit(MorphoConfirming(data, operation));
        await _updateBackgroundSyncTrigger();
        await _waitForReceipt(operation.transactionHash, emit);
        Future.delayed(const Duration(seconds: 4), _updateWallet);
        if (operation.action == MorphoAction.approve) {
          emit(MorphoPrepared(data, await _signDeposit(operation.amount)));
        } else {
          emit(MorphoConfirmed(await _refreshedData(data), operation));
        }
      } catch (error) {
        emit(MorphoFailure(data, _errorMessage(error)));
      }
    }
  }

  Future<MorphoData> _loadData() async {
    _checkNetwork();
    final apy = _optional(_service.getApy());
    final (shares, walletBalance, availableLiquidity) = await (
      _vault.getShareBalance(_address),
      _vault.getUsdcBalance(_address),
      _vault.getAvailableLiquidity(),
    ).wait;
    final (positionValue, earned) = await (
      _vault.previewRedeem(shares),
      shares > BigInt.zero ? _optional(_service.getEarned(_address)) : Future<Money?>.value(),
    ).wait;
    return MorphoData(
      shares: shares,
      positionValue: positionValue,
      walletBalance: walletBalance,
      availableLiquidity: availableLiquidity,
      apy: await apy,
      earned: earned,
    );
  }

  Future<T?> _optional<T>(Future<T> request) async {
    try {
      return await request.timeout(_apiTimeout);
    } catch (error) {
      printV("Optional Morpho request failed: $error");
      return null;
    }
  }

  Future<MorphoData> _refreshedData(MorphoData previous) async {
    try {
      return await _loadData();
    } catch (error) {
      printV("Morpho refresh failed: ${error.runtimeType}");
      return previous;
    }
  }

  Future<MorphoOperation> _prepareDeposit(Money amount) async {
    _checkNetwork();
    if (amount.sign <= 0) {
      throw const MorphoNonPositiveAmountException();
    }
    final (balance, allowance) =
        await (_vault.getUsdcBalance(_address), _vault.getUsdcAllowance(_address)).wait;
    if (amount > balance) {
      throw const MorphoInsufficientBalanceException();
    }
    if (allowance < amount) {
      return _sign(MorphoAction.approve, amount, _vault.usdcApproveCall());
    }
    return _signDeposit(amount);
  }

  Future<MorphoOperation> _signDeposit(Money amount) =>
      _sign(MorphoAction.deposit, amount, _vault.depositCall(amount, _address));

  Future<MorphoOperation> _prepareWithdraw(Money amount, MorphoData data) {
    if (amount.sign <= 0) {
      throw const MorphoNonPositiveAmountException();
    }
    final withdrawable = data.withdrawableNow;
    if (withdrawable != null && amount > withdrawable) {
      throw const MorphoExceedsWithdrawableException();
    }
    if (amount == data.positionValue) {
      return _sign(
        MorphoAction.withdrawAll,
        amount,
        _vault.redeemCall(data.shares, _address),
      );
    }
    return _sign(MorphoAction.withdraw, amount, _vault.withdrawCall(amount, _address));
  }

  Future<MorphoOperation> _sign(
    MorphoAction action,
    Money amount,
    ContractCall call,
  ) async {
    await _vault.dryRun(call);
    _checkNetwork();
    if (isClosed) {
      throw StateError("Closed before signing");
    }
    final transaction = await _evm.createRawCallDataTransaction(
      _wallet,
      call.to,
      call.data,
      Money.zero(CryptoCurrency.eth),
      _settingsStore.getPriority(_wallet.type, chainId: MorphoVault.chainId),
      useBlinkProtection: _settingsStore.useBlinkProtection,
    );
    if (transaction.fee.isZero) {
      throw TransactionNoFeeException();
    }
    return MorphoOperation(action: action, amount: amount, transaction: transaction);
  }

  Future<void> _updateBackgroundSyncTrigger() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(
        PreferencesKey.backgroundSyncLastTrigger(_wallet.name),
        DateTime.now().add(const Duration(minutes: 1)).toIso8601String(),
      );
    } catch (error) {
      printV("Failed to update background sync after Morpho transaction: $error");
    }
  }

  Future<void> _updateWallet() async {
    try {
      await Future.wait([_wallet.updateTransactionsHistory(), _wallet.updateBalance()!]);
    } catch (error) {
      printV("Failed to update wallet after Morpho transaction: ${error.runtimeType}");
    }
  }

  Future<void> _waitForReceipt(String transactionHash, Emitter<MorphoState> emit) async {
    while (!emit.isDone) {
      final status = await _evm
          .getTransactionReceipt(_wallet, transactionHash)
          .timeout(_receiptPollInterval, onTimeout: () => null);
      switch (status) {
        case true:
          return;
        case false:
          throw const MorphoTransactionFailedException();
        case null:
          await Future<void>.delayed(_receiptPollInterval);
      }
    }
    throw StateError("Closed while waiting for $transactionHash");
  }

  void _checkNetwork() {
    if (_wallet.chainId != MorphoVault.chainId) {
      throw const MorphoMainnetRequiredException();
    }
  }

  String _errorMessage(Object error) {
    printV("Morpho error: ${error.runtimeType}");
    return switch (error) {
      MorphoNonPositiveAmountException() => S.current.error_text_input_below_minimum_limit,
      MorphoInsufficientBalanceException() ||
      MorphoExceedsWithdrawableException() =>
        S.current.error_text_input_above_maximum_limit,
      MorphoMainnetRequiredException() => S.current.yield_mainnet_only,
      MorphoTransactionFailedException() => S.current.transaction_reverted,
      TransactionNoFeeException() => S.current.tx_zero_fee_exception,
      ParallelWaitError() => S.current.load_failed,
      CakeException(:final message) => message,
      _ => S.current.please_try_again_later,
    };
  }
}
