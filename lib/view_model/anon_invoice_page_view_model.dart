import 'package:cake_wallet/anonpay/anonpay_api.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/anonpay/anonpay_request.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'anon_invoice_page_view_model.g.dart';

class AnonInvoicePageViewModel = AnonInvoicePageViewModelBase with _$AnonInvoicePageViewModel;

abstract class AnonInvoicePageViewModelBase with Store {
  AnonInvoicePageViewModelBase(this.anonPayApi, this.address, this.settingsStore, this._wallet,
      this._anonpayInvoiceInfoSource)
      : receipientEmail = '',
        receipientName = '',
        description = '',
        amount = '',
        state = InitialExecutionState(),
        selectedCurrency = walletTypeToCryptoCurrency(_wallet.type),
        cryptoCurrency = walletTypeToCryptoCurrency(_wallet.type) {
    _fetchLimits();
  }

  List<Currency> get currencies => [walletTypeToCryptoCurrency(_wallet.type), ...FiatCurrency.all];
  final AnonPayApi anonPayApi;
  final String address;
  final SettingsStore settingsStore;
  final WalletBase _wallet;
  final Box<AnonpayInvoiceInfo> _anonpayInvoiceInfoSource;

  @observable
  Currency selectedCurrency;

  CryptoCurrency cryptoCurrency;

  @observable
  String receipientEmail;

  @observable
  String receipientName;

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
    if (currency is CryptoCurrency) {
      cryptoCurrency = currency;
      _fetchLimits();
    }
  }

  @action
  Future<void> createInvoice() async {
    state = IsExecutingState();
    final result = await anonPayApi.createInvoice(AnonPayRequest(
      cryptoCurrency: cryptoCurrency,
      address: address,
      amount: amount,
      description: description,
      email: receipientEmail,
      name: receipientName,
      fiatEquivalent: selectedCurrency is FiatCurrency
          ? (selectedCurrency as FiatCurrency).raw
          : settingsStore.fiatCurrency.raw,
    ));

    _anonpayInvoiceInfoSource.add(result);

    state = ExecutedSuccessfullyState(payload: result);
  }

  Future<void> _fetchLimits() async {
    final limit = await anonPayApi.fetchLimits(currency: cryptoCurrency);
    minimum = limit.min;
    maximum = limit.max != null ? limit.max! / 4 : null;
  }

  @action
  void reset() {
    selectedCurrency = walletTypeToCryptoCurrency(_wallet.type);
    receipientEmail = '';
    receipientName = '';
    description = '';
    amount = '';
    _fetchLimits();
  }
}
