import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/lightning_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'lightning_invoice_page_view_model.g.dart';

class LightningInvoicePageViewModel = LightningInvoicePageViewModelBase
    with _$LightningInvoicePageViewModel;

abstract class LightningInvoicePageViewModelBase with Store {
  LightningInvoicePageViewModelBase(
    this.settingsStore,
    this._wallet,
    this.sharedPreferences,
    this.lightningViewModel,
  )   : description = '',
        amount = '',
        state = InitialExecutionState(),
        selectedCurrency = walletTypeToCryptoCurrency(_wallet.type),
        cryptoCurrency = walletTypeToCryptoCurrency(_wallet.type) {
    _fetchLimits();
  }

  List<Currency> get currencies => [walletTypeToCryptoCurrency(_wallet.type), ...FiatCurrency.all];
  final SettingsStore settingsStore;
  final WalletBase _wallet;
  final SharedPreferences sharedPreferences;
  final LightningViewModel lightningViewModel;

  @observable
  Currency selectedCurrency;

  CryptoCurrency cryptoCurrency;

  @observable
  String description;

  @observable
  String amount;

  @observable
  ExecutionState state;

  @computed
  int get selectedCurrencyIndex => currencies.indexOf(selectedCurrency);

  @observable
  double? minimum;

  @observable
  double? maximum;

  @action
  void selectCurrency(Currency currency) {
    selectedCurrency = currency;
    maximum = minimum = null;
    if (currency is CryptoCurrency) {
      cryptoCurrency = currency;
    } else {
      cryptoCurrency = walletTypeToCryptoCurrency(_wallet.type);
    }

    _fetchLimits();
  }

  @action
  Future<void> createInvoice() async {
    state = IsExecutingState();
    if (amount.isNotEmpty) {
      final amountInCrypto = double.tryParse(amount);
      if (amountInCrypto == null) {
        state = FailureState('Amount is invalid');
        return;
      }
      if (minimum != null && amountInCrypto < minimum!) {
        state = FailureState('Amount is too small');
        return;
      }
      if (amountInCrypto > 4000000) {
        state = FailureState('Amount is too big');
        return;
      }
    }

    try {
      String bolt11 =
          await lightningViewModel.createInvoice(amountSats: amount, description: description);
      state = ExecutedSuccessfullyState(payload: bolt11);
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  void setRequestParams({
    required String inputAmount,
    required String inputDescription,
  }) {
    description = inputDescription;
    amount = inputAmount;
  }

  Future<void> _fetchLimits() async {
    final limits = await lightningViewModel.invoiceSoftLimitsSats();
    minimum = limits.minFee.toDouble();
    maximum = limits.inboundLiquidity.toDouble();
  }

  @action
  void reset() {
    selectedCurrency = walletTypeToCryptoCurrency(_wallet.type);
    cryptoCurrency = walletTypeToCryptoCurrency(_wallet.type);
    description = '';
    amount = '';
    try {
      _fetchLimits();
    } catch (_) {}
  }
}
