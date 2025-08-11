import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/parse_fixed.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'deuro_view_model.g.dart';

class DEuroViewModel = DEuroViewModelBase with _$DEuroViewModel;

abstract class DEuroViewModelBase with Store {
  final AppStore _appStore;

  static BigInt get MIN_ACCRUED_INTEREST => BigInt.parse("1000000000000");

  DEuroViewModelBase(
    this._appStore,
    this.balanceViewModel,
    this._settingsStore,
    this._fiatConversationStore,
  ) {
    reloadInterestRate();
    reloadSavingsUserData();
  }

  final BalanceViewModel balanceViewModel;
  final SettingsStore _settingsStore;
  final FiatConversionStore _fiatConversationStore;

  @computed
  bool get isFiatDisabled => balanceViewModel.isFiatDisabled;

  @computed
  bool get isFistTime => _settingsStore.shouldShowDEuroDisclaimer;

  @action
  void acceptDisclaimer() => _settingsStore.shouldShowDEuroDisclaimer = false;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  @computed
  String get pendingTransactionFiatAmountFormatted {
    final amount = transaction == null ? '0.00' : _getDEuroFiatAmount(transaction!.amountFormatted);
    return isFiatDisabled ? '' : '$amount ${fiat.title}';
  }

  @computed
  String get pendingTransactionFeeFiatAmountFormatted {
    var amount = '0.00';
    try {
      if (transaction != null) {
        final feeCurrency = CryptoCurrency.eth;
        amount = calculateFiatAmount(
          price: _fiatConversationStore.prices[feeCurrency]!,
          cryptoAmount: transaction!.feeFormattedValue,
        );
      }
    } catch (_) {}
    return isFiatDisabled ? '' : '$amount ${fiat.title}';
  }

  @computed
  String get accountBalanceFormated {
    final dEuroKey = balanceViewModel.balances.keys
        .firstWhereOrNull((e) => e.title == CryptoCurrency.deuro.title);
    if (dEuroKey == null) return '0.00';
    return balanceViewModel.balances[dEuroKey]?.availableBalance ?? '0.00';
  }

  @observable
  BigInt savingsBalance = BigInt.zero;

  @computed
  String get savingsBalanceFormated =>
      ethereum!.formatterEthereumAmountToDouble(amount: savingsBalance).toStringAsFixed(6);

  @computed
  String get fiatSavingsBalanceFormated => _getDEuroFiatAmount(savingsBalanceFormated);

  @observable
  ExecutionState state = InitialExecutionState();

  @observable
  String interestRateFormated = '0';

  @observable
  BigInt accruedInterest = BigInt.zero;

  @computed
  String get accruedInterestFormated =>
      ethereum!.formatterEthereumAmountToDouble(amount: accruedInterest).toStringAsFixed(6);

  @computed
  String get fiatAccruedInterestFormated => _getDEuroFiatAmount(accruedInterestFormated);

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
  PendingTransaction? transaction = null;

  @observable
  PendingTransaction? approvalTransaction = null;

  @action
  Future<void> reloadSavingsUserData() async {
    approvedTokens = await ethereum!.getDEuroSavingsApproved(_appStore.wallet!);
    savingsBalance = await ethereum!.getDEuroSavingsBalance(_appStore.wallet!);
    accruedInterest = await ethereum!.getDEuroAccruedInterest(_appStore.wallet!);
    isLoading = false;
  }

  @action
  Future<void> reloadInterestRate() async {
    final interestRateRaw = await ethereum!.getDEuroInterestRate(_appStore.wallet!);

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
      final priority = _appStore.settingsStore.priority[WalletType.ethereum]!;
      approvalTransaction = await ethereum!.enableDEuroSaving(_appStore.wallet!, priority);
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> prepareSavingsEdit(String amountRaw, bool isAdding) async {
    try {
      state = TransactionCommitting();
      final amount = parseFixed(amountRaw, 18);
      final priority = _appStore.settingsStore.priority[WalletType.ethereum]!;
      actionType = isAdding ? DEuroActionType.deposit : DEuroActionType.withdraw;
      transaction = await (isAdding
          ? ethereum!.addDEuroSaving(_appStore.wallet!, amount, priority)
          : ethereum!.removeDEuroSaving(_appStore.wallet!, amount, priority));
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> prepareCollectInterest() => prepareSavingsEdit(accruedInterestFormated, false);

  Future<void> prepareReinvestInterest() async {
    try {
      state = TransactionCommitting();
      actionType = DEuroActionType.reinvest;
      final priority = _appStore.settingsStore.priority[WalletType.ethereum]!;
      transaction = await ethereum!.reinvestDEuroInterest(_appStore.wallet!, priority);
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
        reloadSavingsUserData();
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
        reloadSavingsUserData();
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

  String _getDEuroFiatAmount(String amount) {
    try {
      var dEuro = CryptoCurrency.deuro;
      final keys = _fiatConversationStore.prices.keys.toList();
      for (final key in keys) {
        if (key.title == "DEURO") dEuro = key;
      }
      return calculateFiatAmount(
        price: _fiatConversationStore.prices[dEuro]!,
        cryptoAmount: amount,
      );
    } catch (_) {
      return '0.00';
    }
  }
}

class NoEtherState extends ExecutionState {}

enum DEuroActionType {
  deposit,
  withdraw,
  reinvest,
  none;
}
