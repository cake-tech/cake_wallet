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

part "stablecoin_yield_event.dart";
part "stablecoin_yield_state.dart";

class StablecoinYieldBloc extends Bloc<StablecoinYieldEvent, StablecoinYieldState> {
  StablecoinYieldBloc({
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
        super(const StablecoinYieldLoading(null)) {
    on<StablecoinYieldEvent>(
      (event, emit) => switch (event) {
        LoadYieldData() => _onLoadYieldData(emit),
        PrepareTransaction() => _onPrepareTransaction(event, emit),
        SubmitTransaction() => _onSubmitTransaction(emit),
      },
      transformer: droppable(),
    );

    add(const LoadYieldData());
  }

  static const _apyTimeout = Duration(seconds: 10);
  static const _receiptPollInterval = Duration(seconds: 3);

  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final EVM _evm;
  final MorphoVault _vault;
  final MorphoService _service;
  final String _address;

  Future<void> _onLoadYieldData(Emitter<StablecoinYieldState> emit) async {
    emit(StablecoinYieldLoading(state.data));
    try {
      emit(StablecoinYieldReady(await _loadData()));
    } catch (error) {
      emit(StablecoinYieldFailure(state.data, error));
    }
  }

  Future<void> _onPrepareTransaction(
    PrepareTransaction event,
    Emitter<StablecoinYieldState> emit,
  ) async {
    final data = state.data;
    if (data == null) {
      return;
    }

    emit(StablecoinYieldPreparing(data));
    try {
      final operation = switch (event) {
        PrepareDeposit(:final amount) => await _prepareDeposit(amount),
        PrepareWithdraw(:final amount) => await _prepareWithdraw(amount, data),
        PrepareWithdrawAll() => await _prepareWithdraw(data.positionValue, data),
      };
      emit(StablecoinYieldPrepared(data, operation));
    } catch (error) {
      emit(StablecoinYieldFailure(data, error));
    }
  }

  Future<void> _onSubmitTransaction(Emitter<StablecoinYieldState> emit) async {
    if (state case StablecoinYieldPrepared(:final data, :final operation)) {
      emit(StablecoinYieldSubmitting(data, operation));
      try {
        _checkNetwork();
        await operation.transaction.commit();
        emit(StablecoinYieldConfirming(data, operation));
        await _waitForReceipt(operation.transactionHash, emit);
        if (operation.action == StablecoinYieldAction.approve) {
          emit(StablecoinYieldPrepared(data, await _signDeposit(operation.amount)));
        } else {
          emit(StablecoinYieldConfirmed(await _refreshedData(data), operation));
        }
      } catch (error) {
        emit(StablecoinYieldFailure(data, error));
      }
    }
  }

  Future<StablecoinYieldData> _loadData() async {
    _checkNetwork();
    final (shares, availableLiquidity, apy) = await (
      _vault.getShareBalance(_address),
      _vault.getAvailableLiquidity(),
      _loadApy(),
    ).wait;
    return StablecoinYieldData(
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

  Future<StablecoinYieldData> _refreshedData(StablecoinYieldData previous) async {
    try {
      return await _loadData();
    } catch (error) {
      printV("Stablecoin yield refresh failed: $error");
      return previous;
    }
  }

  Future<StablecoinYieldOperation> _prepareDeposit(Money amount) async {
    _checkNetwork();
    if (amount.sign <= 0) {
      throw StablecoinYieldError.nonPositiveAmount;
    }
    final (balance, allowance) =
        await (_vault.getUsdcBalance(_address), _vault.getUsdcAllowance(_address)).wait;
    if (amount > balance) {
      throw StablecoinYieldError.exceedsBalance;
    }
    if (allowance < amount) {
      return _sign(StablecoinYieldAction.approve, amount, _vault.usdcApproveCall(amount));
    }
    return _signDeposit(amount);
  }

  Future<StablecoinYieldOperation> _signDeposit(Money amount) =>
      _sign(StablecoinYieldAction.deposit, amount, _vault.depositCall(amount, _address));

  Future<StablecoinYieldOperation> _prepareWithdraw(Money amount, StablecoinYieldData data) {
    if (amount.sign <= 0) {
      throw StablecoinYieldError.nonPositiveAmount;
    }
    final withdrawable = data.withdrawableNow;
    if (withdrawable != null && amount > withdrawable) {
      throw StablecoinYieldError.exceedsWithdrawable;
    }
    if (amount == data.positionValue) {
      return _sign(
        StablecoinYieldAction.withdrawAll,
        amount,
        _vault.redeemCall(data.shares, _address),
      );
    }
    return _sign(StablecoinYieldAction.withdraw, amount, _vault.withdrawCall(amount, _address));
  }

  Future<StablecoinYieldOperation> _sign(
    StablecoinYieldAction action,
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
      throw StablecoinYieldError.feeEstimateFailed;
    }
    return StablecoinYieldOperation(action: action, amount: amount, transaction: transaction);
  }

  Future<void> _waitForReceipt(String transactionHash, Emitter<StablecoinYieldState> emit) async {
    while (!emit.isDone) {
      final status = await _evm
          .getTransactionReceipt(_wallet, transactionHash)
          .timeout(_receiptPollInterval, onTimeout: () => null);
      switch (status) {
        case true:
          return;
        case false:
          throw StablecoinYieldError.transactionFailed;
        case null:
          await Future<void>.delayed(_receiptPollInterval);
      }
    }
    throw StateError("Closed while waiting for $transactionHash");
  }

  void _checkNetwork() {
    if (_wallet.chainId != MorphoVault.chainId) {
      throw StablecoinYieldError.networkMismatch;
    }
  }
}
