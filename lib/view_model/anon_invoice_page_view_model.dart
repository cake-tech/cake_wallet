import 'package:cake_wallet/anonpay/anonpay_api.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/anonpay/anonpay_request.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'anon_invoice_page_view_model.g.dart';

class AnonInvoicePageViewModel = AnonInvoicePageViewModelBase with _$AnonInvoicePageViewModel;

abstract class AnonInvoicePageViewModelBase with Store {
  AnonInvoicePageViewModelBase(
    this.anonPayApi,
    this.address,
    this.settingsStore,
    this._wallet,
    this._anonpayInvoiceInfoSource,
    this._fiatConversationStore,
    this.sharedPreferences,
    this.pageOption,
  )   : receipientEmail = '',
        receipientName = '',
        description = '',
        amount = '',
        state = InitialExecutionState(),
        selectedCurrency = walletTypeToCryptoCurrency(_wallet.type),
        cryptoCurrency = walletTypeToCryptoCurrency(_wallet.type) {
    _getPreviousDonationLink();      
    _fetchLimits();
  }

  List<Currency> get currencies => [walletTypeToCryptoCurrency(_wallet.type), ...FiatCurrency.all];
  final AnonPayApi anonPayApi;
  final String address;
  final SettingsStore settingsStore;
  final WalletBase _wallet;
  final Box<AnonpayInvoiceInfo> _anonpayInvoiceInfoSource;
  final FiatConversionStore _fiatConversationStore;
  final SharedPreferences sharedPreferences;
  final ReceivePageOption pageOption;

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
    maximum = minimum = null;
    if (currency is CryptoCurrency) {
      cryptoCurrency = currency;
    }
    _fetchLimits();
  }

  @action
  Future<void> createInvoice() async {
    state = IsExecutingState();
    if (amount.isNotEmpty) {
      final amountInCrypto = double.parse(amount);
      if (minimum != null && amountInCrypto < minimum!) {
        state = FailureState('Amount is too small');
        return;
      }
      if (maximum != null && amountInCrypto > maximum!) {
        state = FailureState('Amount is too big');
        return;
      }
    }
    final result = await anonPayApi.createInvoice(AnonPayRequest(
      cryptoCurrency: cryptoCurrency,
      address: address,
      amount: amount.isEmpty ? null : amount,
      description: description,
      email: receipientEmail,
      name: receipientName,
      fiatEquivalent:
          selectedCurrency is FiatCurrency ? (selectedCurrency as FiatCurrency).raw : null,
    ));

    _anonpayInvoiceInfoSource.add(result);

    state = ExecutedSuccessfullyState(payload: result);
  }

  @action
  Future<void> generateDonationLink() async {
    state = IsExecutingState();

    final result = await anonPayApi.generateDonationLink(AnonPayRequest(
      cryptoCurrency: cryptoCurrency,
      address: address,
      description: description,
      email: receipientEmail,
      name: receipientName,
    ));

    await sharedPreferences.setString(PreferencesKey.trocadorDonationLink, result.clearnetUrl);

    state = ExecutedSuccessfullyState(payload: result);
  }

  Future<void> _fetchLimits() async {
    final limit = await anonPayApi.fetchLimits(currency: cryptoCurrency);
    minimum = limit.min;
    maximum = limit.max != null ? limit.max! / 4 : null;
    if (selectedCurrency is FiatCurrency) {
      final fiatPrice = _fiatConversationStore.prices[cryptoCurrency];
      maximum = maximum != null
          ? double.tryParse(calculateFiatAmount(price: fiatPrice, cryptoAmount: maximum.toString()))
          : null;
      minimum = minimum != null
          ? double.tryParse(calculateFiatAmount(price: fiatPrice, cryptoAmount: minimum.toString()))
          : null;
    }
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

  Future<void> _getPreviousDonationLink() async {
    if(pageOption == ReceivePageOption.anonPayDonationLink) {
    final donationLink = sharedPreferences.getString(PreferencesKey.trocadorDonationLink);
      if(donationLink != null){
       final url = Uri.parse(donationLink);
        url.queryParameters.forEach((key, value) {
          if(key == 'name') receipientName = value;
          if(key == 'email') receipientEmail = value;
          if(key == 'description') description = Uri.decodeComponent(value);
        });
        generateDonationLink();
      }
    }
  }
}