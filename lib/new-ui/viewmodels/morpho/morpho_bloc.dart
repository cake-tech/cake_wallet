import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/morpho/morpho_service.dart";
import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:meta/meta.dart";

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
    on<MorphoEvent>(
      (event, emit) => switch (event) {
        YieldDataRequested() => _onYieldDataRequested(emit),
        TransactionRequested() => _onTransactionRequested(event, emit),
        TransactionConfirmed() => _onTransactionConfirmed(event, emit),
      },
      transformer: droppable(),
    );

    add(const YieldDataRequested());
  }

  static const _apyTimeout = Duration(seconds: 10);
  static const _receiptPollInterval = Duration(seconds: 3);

  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final EVM _evm;
  final MorphoVault _vault;
  final MorphoService _service;
  final String _address;

  Future<void> _onYieldDataRequested(Emitter<MorphoState> emit) async {
    emit(MorphoLoading(state.data));
    try {
      emit(MorphoReady(await _loadData()));
    } catch (error) {
      emit(MorphoFailure(state.data, error));
    }
  }

  Future<void> _onTransactionRequested(
    TransactionRequested event,
    Emitter<MorphoState> emit,
  ) async {
    final data = state.data;
    if (data == null) {
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
      emit(MorphoFailure(data, error));
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
        await _waitForReceipt(operation.transactionHash, emit);
        if (operation.action == MorphoAction.approve) {
          emit(MorphoPrepared(data, await _signDeposit(operation.amount)));
        } else {
          emit(MorphoConfirmed(await _refreshedData(data), operation));
        }
      } catch (error) {
        emit(MorphoFailure(data, error));
      }
    }
  }

  Future<MorphoData> _loadData() async {
    _checkNetwork();
    final (shares, availableLiquidity, apy) = await (
      _vault.getShareBalance(_address),
      _vault.getAvailableLiquidity(),
      _loadApy(),
    ).wait;
    return MorphoData(
      shares: shares,
      positionValue: await _vault.previewRedeem(shares),
      availableLiquidity: availableLiquidity,
      apy: apy,
    );
  }

  Future<double?> _loadApy() async {
    try {
      return await _service.getApy().timeout(_apyTimeout);
    } catch (error) {
      printV("Morpho APY unavailable: $error");
      return null;
    }
  }

  Future<MorphoData> _refreshedData(MorphoData previous) async {
    try {
      return await _loadData();
    } catch (error) {
      printV("Stablecoin yield refresh failed: $error");
      return previous;
    }
  }

  Future<MorphoOperation> _prepareDeposit(Money amount) async {
    _checkNetwork();
    if (amount.sign <= 0) {
      throw MorphoError.nonPositiveAmount;
    }
    final (balance, allowance) =
        await (_vault.getUsdcBalance(_address), _vault.getUsdcAllowance(_address)).wait;
    if (amount > balance) {
      throw MorphoError.exceedsBalance;
    }
    if (allowance < amount) {
      return _sign(MorphoAction.approve, amount, _vault.usdcApproveCall(amount));
    }
    return _signDeposit(amount);
  }

  Future<MorphoOperation> _signDeposit(Money amount) =>
      _sign(MorphoAction.deposit, amount, _vault.depositCall(amount, _address));

  Future<MorphoOperation> _prepareWithdraw(Money amount, MorphoData data) {
    if (amount.sign <= 0) {
      throw MorphoError.nonPositiveAmount;
    }
    final withdrawable = data.withdrawableNow;
    if (withdrawable != null && amount > withdrawable) {
      throw MorphoError.exceedsWithdrawable;
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
      throw MorphoError.feeEstimateFailed;
    }
    return MorphoOperation(action: action, amount: amount, transaction: transaction);
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
          throw MorphoError.transactionFailed;
        case null:
          await Future<void>.delayed(_receiptPollInterval);
      }
    }
    throw StateError("Closed while waiting for $transactionHash");
  }

  void _checkNetwork() {
    if (_wallet.chainId != MorphoVault.chainId) {
      throw MorphoError.networkMismatch;
    }
  }
}
