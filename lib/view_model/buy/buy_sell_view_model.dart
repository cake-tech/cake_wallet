import 'dart:async';

import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'buy_sell_view_model.g.dart';

class BuySellViewModel = BuySellViewModelBase with _$BuySellViewModel;

abstract class BuySellViewModelBase extends WalletChangeListenerViewModel with Store {
  @override
  void onWalletChange(wallet) {
    cryptoCurrency = wallet.currency;
  }

  BuySellViewModelBase(
    AppStore appStore,
    this.trades,
    this._exchangeTemplateStore,
    this.tradesStore,
    this._settingsStore,
    this.sharedPreferences,
    this.contactListViewModel,
  )   : _cryptoNumberFormat = NumberFormat(),
        isSendAllEnabled = false,
        isReceiveAmountEntered = false,
        cryptoAmount = '',
        fiatAmount = '',
        receiveAddress = '',
        depositAddress = '',
        isDepositAddressEnabled = false,
        isReceiveAmountEditable = false,
        _useTorOnly = false,
        cryptoCurrencies = <CryptoCurrency>[],
        fiatCurrencies = <FiatCurrency>[],
        limits = Limits(min: 0, max: 0),
        tradeState = ExchangeTradeStateInitial(),
        limitsState = LimitsInitialState(),
        cryptoCurrency = appStore.wallet!.currency,
        fiatCurrency = _settingsStore.fiatCurrency,
        providerList = [],
        sortedAvailableQuotes = ObservableList<Quote>(),
        paymentMethods = ObservableList<PaymentMethod>(),
        super(appStore: appStore) {
    _useTorOnly = _settingsStore.exchangeStatus == ExchangeApiMode.torOnly;
    _setProviders();
    _initializePaymentMethodsAndRates();

    const excludeFiatCurrencies = [];
    const excludeCryptoCurrencies = [
      CryptoCurrency.xlm,
      CryptoCurrency.xrp,
      CryptoCurrency.bnb,
      CryptoCurrency.btt
    ];

    fiatCurrencies =
        FiatCurrency.all.where((currency) => !excludeFiatCurrencies.contains(currency)).toList();
    cryptoCurrencies = CryptoCurrency.all
        .where((currency) => !excludeCryptoCurrencies.contains(currency))
        .toList();
  }

  List<CryptoCurrency> cryptoCurrencies;

  List<FiatCurrency> fiatCurrencies;

  final NumberFormat _cryptoNumberFormat;

  final SettingsStore _settingsStore;

  final ContactListViewModel contactListViewModel;

  late Timer bestRateSync;

  bool _useTorOnly;
  final Box<Trade> trades;
  final ExchangeTemplateStore _exchangeTemplateStore;
  final TradesStore tradesStore;
  final SharedPreferences sharedPreferences;

  List<BuyProvider> get availableBuyProviders {
    final providerTypes = ProvidersHelper.getAvailableBuyProviderTypes(wallet.type);
    return providerTypes
        .map((type) => ProvidersHelper.getProviderByType(type))
        .where((provider) => provider != null)
        .cast<BuyProvider>()
        .toList();
  }

  List<BuyProvider> get availableSellProviders {
    final providerTypes = ProvidersHelper.getAvailableSellProviderTypes(wallet.type);
    return providerTypes
        .map((type) => ProvidersHelper.getProviderByType(type))
        .where((provider) => provider != null)
        .cast<BuyProvider>()
        .toList();
  }

  @observable
  bool isBuyAction = true;

  @observable
  List<BuyProvider> providerList;

  @observable
  ObservableList<Quote> sortedAvailableQuotes;

  @observable
  ObservableList<PaymentMethod> paymentMethods;

  @observable
  FiatCurrency fiatCurrency;

  @observable
  CryptoCurrency cryptoCurrency;

  @observable
  LimitsState limitsState;

  @observable
  ExchangeTradeState tradeState;

  @observable
  String cryptoAmount;

  @observable
  String fiatAmount;

  @observable
  String depositAddress;

  @observable
  String receiveAddress;

  @observable
  bool isDepositAddressEnabled;

  @observable
  bool isReceiveAmountEntered;

  @observable
  bool isReceiveAmountEditable;

  @observable
  bool isSendAllEnabled;

  @observable
  Limits limits;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  ObservableList<ExchangeTemplate> get templates => _exchangeTemplateStore.templates;

  @computed
  Quote? get bestRate => sortedAvailableQuotes.isNotEmpty ? sortedAvailableQuotes.first : null;

  @computed
  PaymentMethod? get selectedPaymentMethod =>
      paymentMethods.isNotEmpty ? paymentMethods.first : null;

  @action
  void changeCryptoCurrency({required CryptoCurrency currency}) {
    cryptoCurrency = currency;
    _onPairChange();
  }

  @action
  void changeFiatCurrency({required FiatCurrency currency}) {
    fiatCurrency = currency;
    _onPairChange();
  }

  @action
  void changePaymentMethod(PaymentMethod paymentMethod) {
    paymentMethods.remove(paymentMethod);
    paymentMethods.insert(0, paymentMethod);
    _calculateBestRate(selectedPaymentMethod: paymentMethod);
  }

  @action
  void changeQuote(Quote Quote) {
    sortedAvailableQuotes.remove(Quote);
    sortedAvailableQuotes.insert(0, Quote);
  }

  void _onPairChange() {
    cryptoAmount = '';
    fiatAmount = '';
    _initializePaymentMethodsAndRates();
  }

  void _setProviders() {
    providerList = isBuyAction ? availableBuyProviders : availableSellProviders;
  }

  Future<void> _initializePaymentMethodsAndRates() async {
    await _getAvailablePaymentTypes();
    if (selectedPaymentMethod != null) {
      await _calculateBestRate(selectedPaymentMethod: selectedPaymentMethod!);
    }
  }

  Future<void> _getAvailablePaymentTypes() async {
    final result = await Future.wait(providerList.map((element) => element.getAvailablePaymentTypes(
          fiatCurrency: fiatCurrency.title,
          type: isBuyAction ? 'buy' : 'sell',
        )));

    paymentMethods = ObservableList<PaymentMethod>.of(
        result.where((element) => element.isNotEmpty).expand((element) => element));
  }

  Future<void> _calculateBestRate({required PaymentMethod selectedPaymentMethod}) async {
    final amount = double.tryParse(isBuyAction ? fiatAmount : cryptoAmount) ?? 100;
    final result = await Future.wait<Quote?>(providerList.map((element) => element.fetchRate(
          sourceCurrency: isBuyAction ? fiatCurrency.title : cryptoCurrency.title,
          destinationCurrency: isBuyAction ? cryptoCurrency.title : fiatCurrency.title,
          amount: amount.toInt(),
          paymentMethod: selectedPaymentMethod.paymentMethodType!,
          uuid: 'acad3928-556f-48a1-a478-4e2ec76700cd',
          clientName: 'CakeWallet',
          type: isBuyAction ? 'buy' : 'sell',
          walletAddress: wallet.walletAddresses.address,
          isRecurringPayment: false,
          input: 'source',
        )));

    final validQuotes = result.where((quote) => quote != null).cast<Quote>().toList();
    validQuotes.sort((a, b) => b.rate.compareTo(a.rate));
    sortedAvailableQuotes
      ..clear()
      ..addAll(validQuotes);
  }
}
