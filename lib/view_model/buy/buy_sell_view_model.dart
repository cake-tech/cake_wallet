import 'dart:async';

import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/buy/sell_buy_states.dart';
import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';

part 'buy_sell_view_model.g.dart';

class BuySellViewModel = BuySellViewModelBase with _$BuySellViewModel;

abstract class BuySellViewModelBase extends WalletChangeListenerViewModel with Store {
  BuySellViewModelBase(
    AppStore appStore,
  )   : _cryptoNumberFormat = NumberFormat(),
        cryptoAmount = '',
        fiatAmount = '',
        cryptoCurrencyAddress = '',
        cryptoCurrencies = <CryptoCurrency>[],
        fiatCurrencies = <FiatCurrency>[],
        paymentMethodState = InitialPaymentMethod(),
        buySellQuotState = InitialBuySellQuotState(),
        cryptoCurrency = appStore.wallet!.currency,
        fiatCurrency = appStore.settingsStore.fiatCurrency,
        providerList = [],
        sortedRecommendedQuotes = ObservableList<Quote>(),
        sortedQuotes = ObservableList<Quote>(),
        paymentMethods = ObservableList<PaymentMethod>(),
        settingsStore = appStore.settingsStore,
        super(appStore: appStore) {
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
    _initialize();
  }

  @observable
  List<CryptoCurrency> cryptoCurrencies;

  @observable
  List<FiatCurrency> fiatCurrencies;

  final NumberFormat _cryptoNumberFormat;
  late Timer bestRateSync;

  List<BuyProvider> get availableBuyProviders {
    // final providerTypes = ProvidersHelper.getAvailableBuyProviderTypes(wallet.type);
    final providerTypes = [
      ProviderType.robinhood,
      ProviderType.dfx,
      ProviderType.onramper,
      ProviderType.moonpay,
    ];
    return providerTypes
        .map((type) => ProvidersHelper.getProviderByType(type))
        .where((provider) => provider != null)
        .cast<BuyProvider>()
        .toList();
  }

  List<BuyProvider> get availableSellProviders {
    // final providerTypes = ProvidersHelper.getAvailableSellProviderTypes(wallet.type);
    final providerTypes = [
      ProviderType.robinhood,
      ProviderType.dfx,
      ProviderType.onramper,
      ProviderType.moonpay,
    ];
    return providerTypes
        .map((type) => ProvidersHelper.getProviderByType(type))
        .where((provider) => provider != null)
        .cast<BuyProvider>()
        .toList();
  }

  @override
  void onWalletChange(wallet) {
    cryptoCurrency = wallet.currency;
  }

  bool get isDarkTheme => settingsStore.currentTheme.type == ThemeType.dark;

  double get amount {
    final formattedFiatAmount = double.tryParse(fiatAmount) ?? 200.0;
    final formattedCryptoAmount =
        double.tryParse(cryptoAmount) ?? (cryptoCurrency == CryptoCurrency.btc ? 0.001 : 1);

    return isBuyAction ? formattedFiatAmount : formattedCryptoAmount;
  }

  SettingsStore settingsStore;

  List<SelectableItem> get quoteOptions => [
        OptionTitle(title: 'Recommended'),
        ...sortedRecommendedQuotes,
        OptionTitle(title: 'All Providers'),
        ...sortedQuotes
      ];

  @observable
  bool isBuyAction = true;

  @observable
  List<BuyProvider> providerList;

  @observable
  ObservableList<Quote> sortedRecommendedQuotes;

  @observable
  ObservableList<Quote> sortedQuotes;

  @observable
  ObservableList<PaymentMethod> paymentMethods;

  @observable
  FiatCurrency fiatCurrency;

  @observable
  CryptoCurrency cryptoCurrency;

  @observable
  String cryptoAmount;

  @observable
  String fiatAmount;

  @observable
  String cryptoCurrencyAddress;

  @observable
  Quote? bestRateQuote;

  @observable
  Quote? selectedQuote;

  @observable
  PaymentMethod? selectedPaymentMethod;

  @observable
  PaymentMethodLoadingState paymentMethodState;

  @observable
  BuySellQuotLoadingState buySellQuotState;

  @computed
  bool get isReadyToTrade =>
      selectedQuote != null &&
      selectedPaymentMethod != null &&
      paymentMethodState is PaymentMethodLoaded &&
      buySellQuotState is BuySellQuotLoaded;

  @action
  void reset() {
    cryptoCurrency = wallet.currency;
    fiatCurrency = settingsStore.fiatCurrency;
    _initialize();
  }

  @action
  void changeBuySellAction() {
    isBuyAction = !isBuyAction;
    _initialize();
  }

  @action
  void changeFiatCurrency({required FiatCurrency currency}) {
    fiatCurrency = currency;
    _onPairChange();
  }

  @action
  void changeCryptoCurrency({required CryptoCurrency currency}) {
    cryptoCurrency = currency;
    _onPairChange();
  }

  @action
  Future<void> changeFiatAmount({required String amount}) async {
    fiatAmount = amount;

    if (amount.isEmpty) {
      fiatAmount = '';
      cryptoAmount = '';
      return;
    }

    final enteredAmount = double.tryParse(amount.replaceAll(',', '.')) ?? 0;

    if (bestRateQuote == null) {
      cryptoAmount = S.current.fetching;
      await calculateBestRate();
    }

    if (bestRateQuote != null) {
      _cryptoNumberFormat.maximumFractionDigits = cryptoCurrency.decimals;
      cryptoAmount = _cryptoNumberFormat
          .format(enteredAmount / bestRateQuote!.rate)
          .toString()
          .replaceAll(RegExp('\\,'), '');
    }
  }

  @action
  Future<void> changeCryptoAmount({required String amount}) async {
    cryptoAmount = amount;

    if (amount.isEmpty) {
      fiatAmount = '';
      cryptoAmount = '';
      return;
    }

    final enteredAmount = double.tryParse(amount.replaceAll(',', '.')) ?? 0;

    if (bestRateQuote == null) {
      fiatAmount = S.current.fetching;
      await calculateBestRate();
    }

    if (bestRateQuote != null) {
      fiatAmount = _cryptoNumberFormat
          .format(enteredAmount * bestRateQuote!.rate)
          .toString()
          .replaceAll(RegExp('\\,'), '');
    }
  }

  @action
  void changeOption(SelectableOption option) {
    if (option is Quote) {
      sortedRecommendedQuotes.forEach((element) => element.isSelected = false);
      sortedQuotes.forEach((element) => element.isSelected = false);
      option.isSelected = true;
      selectedQuote = option;
    } else if (option is PaymentMethod) {
      paymentMethods.forEach((element) => element.isSelected = false);
      option.isSelected = true;
      selectedPaymentMethod = option;
    } else {
      throw ArgumentError('Unknown option type');
    }
  }

  void _onPairChange() {
    _initialize();
  }

  void _setProviders() =>
      providerList = isBuyAction ? availableBuyProviders : availableSellProviders;

  Future<void> _initialize() async {
    _setProviders();
    cryptoAmount = '';
    fiatAmount = '';
    paymentMethodState = InitialPaymentMethod();
    buySellQuotState = InitialBuySellQuotState();
    await _getAvailablePaymentTypes();
    await calculateBestRate();
  }

  @action
  Future<void> _getAvailablePaymentTypes() async {
    paymentMethodState = PaymentMethodLoading();
    selectedPaymentMethod = null;
    final result = await Future.wait(providerList.map((element) =>
        element.getAvailablePaymentTypes(fiatCurrency.title, cryptoCurrency.title, isBuyAction)));

    final Map<PaymentType, PaymentMethod> uniquePaymentMethods = {};
    for (var methods in result) {
      for (var method in methods) {
        uniquePaymentMethods[method.paymentMethodType] = method;
      }
    }

    paymentMethods = ObservableList<PaymentMethod>.of(uniquePaymentMethods.values);
    if (paymentMethods.isNotEmpty) {
      paymentMethods.insert(0, PaymentMethod.all());
      selectedPaymentMethod = paymentMethods.first;
      selectedPaymentMethod!.isSelected = true;
      paymentMethodState = PaymentMethodLoaded();
    } else {
      paymentMethodState = PaymentMethodFailed();
    }
  }

  @action
  Future<void> calculateBestRate() async {
    buySellQuotState = BuySellQuotLoading();

    final result = await Future.wait<List<Quote>?>(providerList.map((element) => element.fetchQuote(
          sourceCurrency: isBuyAction ? fiatCurrency.title : cryptoCurrency.title,
          destinationCurrency: isBuyAction ? cryptoCurrency.title : fiatCurrency.title,
          amount: amount,
          paymentType: selectedPaymentMethod!.paymentMethodType == PaymentType.all
              ? null
              : selectedPaymentMethod!.paymentMethodType,
          isBuyAction: isBuyAction,
          walletAddress: wallet.walletAddresses.address,
        )));

    sortedRecommendedQuotes.clear();
    sortedQuotes.clear();

    final validQuotes = result
        .where((element) => element != null && element.isNotEmpty)
        .expand((element) => element!)
        .toList();

    if (validQuotes.isEmpty) {
      buySellQuotState = BuySellQuotFailed();
      return;
    }

    validQuotes.sort((a, b) => a.rate.compareTo(b.rate));

    final Set<String> addedProviders = {};
    final List<Quote> uniqueProviderQuotes = validQuotes.where((element) {
      if (addedProviders.contains(element.provider.title)) return false;
      addedProviders.add(element.provider.title);
      return true;
    }).toList();

    sortedRecommendedQuotes.addAll(uniqueProviderQuotes);

    sortedQuotes = ObservableList.of(
        validQuotes.where((element) => !uniqueProviderQuotes.contains(element)).toList());

    if (sortedRecommendedQuotes.isNotEmpty) {
      sortedRecommendedQuotes.first
        ..isBestRate = true
        ..isSelected = true
        ..recommendations.insert(0, ProviderRecommendation.bestRate);
      bestRateQuote = sortedRecommendedQuotes.first;
      selectedQuote = sortedRecommendedQuotes.first;
    }

    buySellQuotState = BuySellQuotLoaded();
  }

  @action
  Future<void> launchTrade(BuildContext context) async {
    final provider = selectedQuote!.provider;

    provider.launchProvider(
      context: context,
      quote: selectedQuote!,
      paymentMethod: selectedPaymentMethod!.paymentMethodType == PaymentType.all
          ? null
          : selectedPaymentMethod,
      amount: amount,
      isBuyAction: isBuyAction,
      cryptoCurrencyAddress: cryptoCurrencyAddress,
    );
  }
}
