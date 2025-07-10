import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/parse_fixed.dart';
import 'package:mobx/mobx.dart';

part 'deuro_view_model.g.dart';

class DEuroViewModel = DEuroViewModelBase with _$DEuroViewModel;

abstract class DEuroViewModelBase with Store {
  final AppStore _appStore;

  DEuroViewModelBase(this._appStore, this.balanceViewModel, this._settingsStore, this._fiatConversationStore) {
    reloadInterestRate();
    reloadSavingsUserData();
  }
  final BalanceViewModel balanceViewModel;
  final SettingsStore _settingsStore;
  final FiatConversionStore _fiatConversationStore;
  
  @computed
  bool get isFiatDisabled => balanceViewModel.isFiatDisabled;

  @computed
  String get pendingTransactionFiatAmountFormatted =>
      isFiatDisabled ? '' : pendingTransactionFiatAmount + ' ' + fiat.title;

  @computed
  String get pendingTransactionFeeFiatAmountFormatted =>
      isFiatDisabled ? '' : pendingTransactionFeeFiatAmount + ' ' + fiat.title;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  
  @computed
  String get pendingTransactionFiatAmount {
    if (transaction == null) {
      return '0.00';
    }

    try {
      final keys = _fiatConversationStore.prices.keys.toList();
      CryptoCurrency deuro = CryptoCurrency.deuro;
      for (var i = 0; i < keys.length; i++) {
        if (keys[i].title == "DEURO") {
          deuro = keys[i];
        }
      }
      final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[deuro]!,
          cryptoAmount: transaction!.amountFormatted);
      return fiat;
    } catch (e) {
      printV(e);
      return '0.02';
    }
  }

  @computed
  String get pendingTransactionFeeFiatAmount {
    try {
      if (transaction != null) {
        final currency = CryptoCurrency.eth;
        final fiat = calculateFiatAmount(
            price: _fiatConversationStore.prices[currency]!,
            cryptoAmount: transaction!.feeFormattedValue,
          );
        return fiat;
      } else {
        return '0.00';
      }
    } catch (_) {
      return '0.00';
    }
  }

  @observable
  String savingsBalance = '0.00';

  @observable
  ExecutionState state = InitialExecutionState();

  @observable
  String interestRate = '0';

  @observable
  String accruedInterest = '0.00';

  @observable
  BigInt approvedTokens = BigInt.zero;

  @computed
  bool get isEnabled => approvedTokens > BigInt.zero;

  @observable
  PendingTransaction? transaction = null;

  @observable
  PendingTransaction? approvalTransaction = null;

  @action
  Future<void> reloadSavingsUserData() async {
    final savingsBalanceRaw = ethereum!.getDEuroSavingsBalance(_appStore.wallet!);
    final accruedInterestRaw = ethereum!.getDEuroAccruedInterest(_appStore.wallet!);

    approvedTokens = await ethereum!.getDEuroSavingsApproved(_appStore.wallet!);

    savingsBalance = ethereum!
        .formatterEthereumAmountToDouble(amount: await savingsBalanceRaw)
        .toStringAsFixed(6);
    accruedInterest = ethereum!
        .formatterEthereumAmountToDouble(amount: await accruedInterestRaw)
        .toStringAsFixed(6);
  }

  @action
  Future<void> reloadInterestRate() async {
    final interestRateRaw = await ethereum!.getDEuroInterestRate(_appStore.wallet!);

    interestRate = (interestRateRaw / BigInt.from(10000)).toString();
  }

  @action
  Future<void> prepareApproval() async {
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
      transaction = await (isAdding
          ? ethereum!.addDEuroSaving(_appStore.wallet!, amount, priority)
          : ethereum!.removeDEuroSaving(_appStore.wallet!, amount, priority));
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> prepareCollectInterest() => prepareSavingsEdit(accruedInterest, false);

  @action
  Future<void> commitTransaction() async {
    if (transaction != null) {
      try {
        state = TransactionCommitting();
        await transaction!.commit();
        transaction = null;
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
    state = InitialExecutionState();
  }
}
