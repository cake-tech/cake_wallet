import "dart:async";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cake_wallet/view_model/send/send_view_model_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency/currency.dart";
import "package:cw_core/currency/fiat_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/wallet_base.dart";
import "package:mobx/mobx.dart";

part "deuro_view_model.g.dart";

class DEuroViewModel = DEuroViewModelBase with _$DEuroViewModel;

abstract class DEuroViewModelBase with Store {
  DEuroViewModelBase(
      this._appStore,
      this.balanceViewModel,
      this._fiatConversationStore, [
        this.hardwareWalletViewModel,
      ]) {
    reloadInterestRate();
    reloadSavingsUserData();
  }

  static CryptoMoney get MIN_ACCRUED_INTEREST =>
      Money(BigInt.parse("1000000000000"), CryptoCurrency.deuro);

  static CryptoMoney get ZERO => Money.zero(CryptoCurrency.deuro);

  final AppStore _appStore;
  final BalanceViewModel balanceViewModel;
  final HardwareWalletViewModel? hardwareWalletViewModel;
  final FiatConversionStore _fiatConversationStore;

  WalletBase get wallet => _appStore.wallet!;

  @computed
  bool get isFiatDisabled => balanceViewModel.isFiatDisabled;

  @computed
  bool get isFistTime => _appStore.settingsStore.shouldShowDEuroDisclaimer;

  @action
  void acceptDisclaimer() => _appStore.settingsStore.shouldShowDEuroDisclaimer = false;

  FiatCurrency get fiat => _appStore.settingsStore.fiatCurrency;

  @computed
  Money<Currency>? get pendingTransactionFiatAmount =>
      isFiatDisabled ? null : _getDEuroFiatAmount(transaction?.amount);

  @computed
  Money<Currency>? get pendingTransactionFeeFiatAmount {
    if (isFiatDisabled) {
      return null;
    }

    try {
      if (transaction != null) {
        const feeCurrency = CryptoCurrency.eth;
        final price = _fiatConversationStore.prices[feeCurrency];
        final rate = _fiatConversationStore.getExchangeRate(feeCurrency, fiat, price);
        return rate.convert(transaction!.fee);
      }
    } catch (_) {}
    return Money.zero(fiat);
  }

  @computed
  CryptoMoney get accountBalance {
    final dEuroKey = balanceViewModel.balances.keys
        .firstWhereOrNull((e) => e.title == CryptoCurrency.deuro.title);
    if (dEuroKey == null) {
      return ZERO;
    }
    return wallet.balance[dEuroKey]?.available ?? ZERO;
  }

  @observable
  CryptoMoney savingsBalance = ZERO;

  @computed
  Money<Currency> get fiatSavingsBalance => _getDEuroFiatAmount(savingsBalance);

  @observable
  CryptoMoney? savingsBalanceV1;

  @computed
  Money<Currency> get fiatSavingsBalanceV1 => _getDEuroFiatAmount(savingsBalanceV1);

  @observable
  ExecutionState state = InitialExecutionState();

  @observable
  String interestRateFormated = "0";

  @observable
  CryptoMoney accruedInterest = ZERO;

  @computed
  Money<Currency> get fiatAccruedInterest => _getDEuroFiatAmount(accruedInterest);

  @observable
  BigInt approvedTokens = BigInt.zero;

  @computed
  bool get isEnabled => approvedTokens > BigInt.zero;

  @computed
  bool get isSavingsActionsEnabled => isEnabled && accruedInterest >= MIN_ACCRUED_INTEREST;

  @observable
  bool isLoading = true;

  @observable
  DEuroActionType actionType = DEuroActionType.none;

  @observable
  PendingTransaction? transaction;

  @observable
  PendingTransaction? approvalTransaction;

  @action
  Future<void> reloadSavingsUserData() async {
    approvedTokens = await evm!.getDEuroSavingsApproved(_appStore.wallet!) ?? BigInt.zero;
    savingsBalance = await evm!.getDEuroSavingsBalance(_appStore.wallet!) ?? ZERO;
    accruedInterest = await evm!.getDEuroAccruedInterest(_appStore.wallet!) ?? ZERO;

    final v1Balance = await evm!.getDEuroSavingsV1Balance(_appStore.wallet!) ?? ZERO;
    savingsBalanceV1 = v1Balance.isZero ? null : v1Balance;

    isLoading = false;
  }

  @action
  Future<void> reloadInterestRate() async {
    final interestRateRaw = await evm!.getDEuroInterestRate(_appStore.wallet!) ?? BigInt.zero;

    interestRateFormated = (interestRateRaw / BigInt.from(10000)).toString();
  }

  @action
  Future<void> prepareApproval() async {
    final ethBalance = balanceViewModel.balances[CryptoCurrency.eth]?.availableBalance ?? "0";
    if ((double.tryParse(ethBalance) ?? 0) == 0) {
      state = NoEtherState();
      return;
    }
    try {
      state = TransactionCommitting();
      final priority = _appStore.settingsStore.getPriority(wallet.type, chainId: wallet.chainId)!;
      final approval = await evm!.enableDEuroSaving(_appStore.wallet!, priority);
      if (approval == null) {
        throw Exception("DEuro saving not available");
      }

      approvalTransaction = approval;
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> prepareSavingsEdit(Money amount, {required bool isAdding}) async {
    try {
      state = TransactionCommitting();

      if (amount.isZero) {
        throw Exception("Invalid amount: amount cannot be zero");
      }

      final priority = _appStore.settingsStore.getPriority(wallet.type, chainId: wallet.chainId)!;
      actionType = isAdding ? DEuroActionType.deposit : DEuroActionType.withdraw;
      final tx = await (isAdding
          ? evm!.addDEuroSaving(_appStore.wallet!, amount.amount, priority)
          : evm!.removeDEuroSaving(_appStore.wallet!, amount.amount, priority));
      if (tx == null) {
        throw Exception("DEuro saving not available");
      }

      transaction = tx;
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> prepareSavingsV1Withdraw() async {
    try {
      state = TransactionCommitting();
      actionType = DEuroActionType.withdraw;
      final priority = _appStore.settingsStore.getPriority(wallet.type, chainId: wallet.chainId)!;
      final tx = await evm!.withdrawDEuroSavingV1(_appStore.wallet!, priority);
      if (tx == null) {
        throw Exception("DEuro saving not available");
      }

      transaction = tx;
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> prepareCollectInterest() async {
    if (accruedInterest < MIN_ACCRUED_INTEREST) {
      state = FailureState("Accrued interest is below minimum threshold");
      return;
    }

    await prepareSavingsEdit(accruedInterest, isAdding: false);
  }

  Future<void> prepareReinvestInterest() async {
    try {
      state = TransactionCommitting();
      actionType = DEuroActionType.reinvest;
      final priority = _appStore.settingsStore.getPriority(wallet.type, chainId: wallet.chainId)!;
      final tx = await evm!.reinvestDEuroInterest(_appStore.wallet!, priority);
      if (tx == null) {
        throw Exception("DEuro saving not available");
      }

      transaction = tx;
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> commitTransaction() async {
    if (transaction != null) {
      try {
        state = TransactionCommitting();
        await transaction!.commit();
        transaction = null;
        actionType = DEuroActionType.none;
        unawaited(reloadSavingsUserData());
        state = TransactionCommitted();
      } catch (e) {
        state = FailureState(e.toString());
      }
    }
  }

  @action
  Future<void> commitApprovalTransaction() async {
    if (approvalTransaction != null) {
      try {
        state = TransactionCommitting();
        await approvalTransaction!.commit();
        approvalTransaction = null;
        unawaited(reloadSavingsUserData());
        state = TransactionCommitted();
      } catch (e) {
        state = FailureState(e.toString());
      }
    }
  }

  @action
  void dismissTransaction() {
    transaction = null;
    approvalTransaction = null;
    actionType = DEuroActionType.none;
    state = InitialExecutionState();
  }

  Money _getDEuroFiatAmount(Money? amount) {
    if (amount == null) {
      return Money.zero(fiat);
    }

    try {
      var dEuro = CryptoCurrency.deuro;
      final keys = _fiatConversationStore.prices.keys.toList();
      for (final key in keys) {
        if (key.title == "DEURO") {
          dEuro = key;
        }
      }
      final price = _fiatConversationStore.prices[dEuro];
      final rate = _fiatConversationStore.getExchangeRate(CryptoCurrency.deuro, fiat, price);

      return rate.convert(amount);
    } catch (_) {
      return Money.zero(fiat);
    }
  }
}

class NoEtherState extends ExecutionState {}

enum DEuroActionType { deposit, withdraw, reinvest, none }
