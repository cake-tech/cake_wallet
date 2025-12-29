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
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';

part 'buy_sell_view_model.g.dart';

class BuySellViewModel = BuySellViewModelBase with _$BuySellViewModel;

abstract class BuySellViewModelBase extends WalletChangeListenerViewModel with Store {
  BuySellViewModelBase(
    AppStore appStore,
  )   : _cryptoAmount = '',
        fiatAmount = '',
        cryptoCurrencyAddress = '',
        isCryptoCurrencyAddressEnabled = false,
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
        _appStore = appStore,
        super(appStore: appStore) {
    const excludeFiatCurrencies = [];
    const excludeCryptoCurrencies = [];

    fiatCurrencies =
        FiatCurrency.all.where((currency) => !excludeFiatCurrencies.contains(currency)).toList();
    cryptoCurrencies = CryptoCurrency.all
        .where((currency) => !excludeCryptoCurrencies.contains(currency))
        .toList();
    _initialize();

    isCryptoCurrencyAddressEnabled = !(cryptoCurrency == wallet.currency);
  }

  late Timer bestRateSync;

  List<BuyProvider> get availableBuyProviders {
    final providerTypes = ProvidersHelper.getAvailableBuyProviderTypes();
    return providerTypes
        .map((type) => ProvidersHelper.getProviderByType(type))
        .cast<BuyProvider>()
        .toList();
  }

  List<BuyProvider> get availableSellProviders {
    final providerTypes = ProvidersHelper.getAvailableSellProviderTypes();
    return providerTypes
        .map((type) => ProvidersHelper.getProviderByType(type))
        .cast<BuyProvider>()
        .toList();
  }

  @override
  void onWalletChange(wallet) {
    cryptoCurrency = wallet.currency;
  }

  double get amount {
    final formattedFiatAmount = double.tryParse(fiatAmount);
    final formattedCryptoAmount = double.tryParse(_cryptoAmount);

    return isBuyAction
        ? formattedFiatAmount ?? 200.0
        : formattedCryptoAmount ?? (cryptoCurrency == CryptoCurrency.btc ? 0.001 : 1);
  }

  final AppStore _appStore;

  Quote? bestRateQuote;

  Quote? selectedQuote;

  @observable
  List<CryptoCurrency> cryptoCurrencies;

  @observable
  List<FiatCurrency> fiatCurrencies;

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
  String _cryptoAmount;

  @computed
  String get cryptoAmount =>
      _appStore.amountParsingProxy.getDisplayCryptoAmount(_cryptoAmount, cryptoCurrency);

  @observable
  String fiatAmount;

  @observable
  String cryptoCurrencyAddress;

  @observable
  bool isCryptoCurrencyAddressEnabled;

  @observable
  PaymentMethod? selectedPaymentMethod;

  @observable
  PaymentMethodLoadingState paymentMethodState;

  @observable
  BuySellQuotLoadingState buySellQuotState;

  @observable
  bool skipIsReadyToTradeReaction = false;

  @computed
  bool get isReadyToTrade {
    final hasSelectedQuote = selectedQuote != null;
    final hasSelectedPaymentMethod = selectedPaymentMethod != null;
    final isPaymentMethodLoaded = paymentMethodState is PaymentMethodLoaded;
    final isBuySellQuotLoaded = buySellQuotState is BuySellQuotLoaded;

    return hasSelectedQuote &&
        hasSelectedPaymentMethod &&
        isPaymentMethodLoaded &&
        isBuySellQuotLoaded;
  }

  @computed
  bool get isBuySellQuoteFailed => buySellQuotState is BuySellQuotFailed;

  @computed
  String? get buySellQuoteFailedError => buySellQuotState is BuySellQuotFailed
      ? (buySellQuotState as BuySellQuotFailed).errorMessage
      : null;

  @computed
  bool get useSatoshi => _appStore.amountParsingProxy.useSatoshi(cryptoCurrency);

  @action
  void reset() {
    cryptoCurrency = wallet.currency;
    fiatCurrency = _appStore.settingsStore.fiatCurrency;
    isCryptoCurrencyAddressEnabled = !(cryptoCurrency == wallet.currency);
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
    isCryptoCurrencyAddressEnabled = !(cryptoCurrency == wallet.currency);
  }

  @action
  void changeCryptoCurrencyAddress(String address) => cryptoCurrencyAddress = address;

  @action
  Future<void> changeFiatAmount({required String amount}) async {
    fiatAmount = amount;

    if (amount.isEmpty) {
      fiatAmount = '';
      _cryptoAmount = '';
      return;
    }

    if (!isReadyToTrade && !isBuySellQuoteFailed) {
      _cryptoAmount = S.current.fetching;
      return;
    } else if (isBuySellQuoteFailed) {
      _cryptoAmount = '';
      return;
    }

    if (bestRateQuote != null) {
      final enteredAmount = double.tryParse(fiatAmount.replaceAll(',', '.')) ?? 0;
      final amount = enteredAmount / bestRateQuote!.rate;

      _cryptoAmount = amount.toString().withMaxDecimals(cryptoCurrency.decimals);
    } else {
      await calculateBestRate();
    }
  }

  @action
  Future<void> changeCryptoAmount({required String amount}) async {
    _cryptoAmount = _appStore.amountParsingProxy.getCanonicalCryptoAmount(amount, cryptoCurrency);

    if (amount.isEmpty) {
      fiatAmount = '';
      _cryptoAmount = '';
      return;
    }

    if (!isReadyToTrade && !isBuySellQuoteFailed) {
      fiatAmount = S.current.fetching;
      return;
    } else if (isBuySellQuoteFailed) {
      fiatAmount = '';
      return;
    }

    if (bestRateQuote != null) {
      final enteredAmount = double.tryParse(_cryptoAmount.replaceAll(',', '.')) ?? 0;

      fiatAmount =
          (enteredAmount * bestRateQuote!.rate).toString().withMaxDecimals(fiatCurrency.decimals);
    } else {
      await calculateBestRate();
    }
  }

  @action
  void changeOption(SelectableOption option) {
    if (option is Quote) {
      sortedRecommendedQuotes.forEach((element) => element.setIsSelected = false);
      sortedQuotes.forEach((element) => element.setIsSelected = false);
      option.setIsSelected = true;
      selectedQuote = option;
    } else if (option is PaymentMethod) {
      paymentMethods.forEach((element) => element.isSelected = false);
      option.isSelected = true;
      selectedPaymentMethod = option;
    } else {
      throw ArgumentError('Unknown option type');
    }
  }

  void onTapChoseProvider(BuildContext context) async {
    skipIsReadyToTradeReaction = true;
    final initialQuotes = List<Quote>.from(sortedRecommendedQuotes + sortedQuotes);
    await calculateBestRate();
    final newQuotes = (sortedRecommendedQuotes + sortedQuotes);

    for (var quote in newQuotes) quote.limits = null;

    final newQuoteProviders = newQuotes
        .map((quote) => quote.provider.isAggregator ? quote.rampName : quote.provider.title)
        .toSet();

    final outOfLimitQuotes = initialQuotes.where((initialQuote) {
      return !newQuoteProviders.contains(
          initialQuote.provider.isAggregator ? initialQuote.rampName : initialQuote.provider.title);
    }).map((missingQuote) {
      final quote = Quote(
        rate: missingQuote.rate,
        feeAmount: missingQuote.feeAmount,
        networkFee: missingQuote.networkFee,
        transactionFee: missingQuote.transactionFee,
        payout: missingQuote.payout,
        rampId: missingQuote.rampId,
        rampName: missingQuote.rampName,
        rampIconPath: missingQuote.rampIconPath,
        paymentType: missingQuote.paymentType,
        quoteId: missingQuote.quoteId,
        recommendations: missingQuote.recommendations,
        provider: missingQuote.provider,
        isBuyAction: missingQuote.isBuyAction,
        limits: missingQuote.limits,
      );
      quote.setFiatCurrency = missingQuote.fiatCurrency;
      quote.setCryptoCurrency = missingQuote.cryptoCurrency;
      return quote;
    }).toList();

    final updatedQuoteOptions = List<SelectableItem>.from([
      OptionTitle(title: 'Recommended'),
      ...sortedRecommendedQuotes,
      if (sortedQuotes.isNotEmpty) OptionTitle(title: 'All Providers'),
      ...sortedQuotes,
      if (outOfLimitQuotes.isNotEmpty) OptionTitle(title: 'Out of Limits'),
      ...outOfLimitQuotes,
    ]);

    if (context.mounted) {
      await Navigator.of(context).pushNamed(
        Routes.buyOptionsPage,
        arguments: [
          updatedQuoteOptions,
          changeOption,
          launchTrade,
        ],
      ).then((value) => calculateBestRate());
    }
  }

  void _onPairChange() {
    _initialize();
  }

  void _setProviders() =>
      providerList = isBuyAction ? availableBuyProviders : availableSellProviders;

  Future<void> _initialize() async {
    _setProviders();
    _cryptoAmount = '';
    fiatAmount = '';
    cryptoCurrencyAddress = _getInitialCryptoCurrencyAddress();
    paymentMethodState = InitialPaymentMethod();
    buySellQuotState = InitialBuySellQuotState();
    await _getAvailablePaymentTypes();
    await calculateBestRate();
  }

  String _getInitialCryptoCurrencyAddress() {
    return cryptoCurrency == wallet.currency ? wallet.walletAddresses.address : '';
  }

  @action
  Future<void> _getAvailablePaymentTypes() async {
    paymentMethodState = PaymentMethodLoading();
    selectedPaymentMethod = null;
    final result = await Future.wait(providerList.map((element) =>
        element.getAvailablePaymentTypes(fiatCurrency.title, cryptoCurrency, isBuyAction).timeout(
              Duration(seconds: 10),
              onTimeout: () => [],
            )));

    final List<PaymentMethod> tempPaymentMethods = [];

    for (var methods in result) {
      for (var method in methods) {
        final alreadyExists = tempPaymentMethods.any((m) {
          return m.paymentMethodType == method.paymentMethodType &&
              m.customTitle == method.customTitle;
        });

        if (!alreadyExists) {
          tempPaymentMethods.add(method);
        }
      }
    }

    paymentMethods = ObservableList<PaymentMethod>.of(tempPaymentMethods);

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

    final List<BuyProvider> validProviders = providerList.where((provider) {
      if (isBuyAction) {
        return provider.supportedCryptoList
            .any((pair) => pair.from == cryptoCurrency && pair.to == fiatCurrency);
      } else {
        return provider.supportedFiatList
            .any((pair) => pair.from == fiatCurrency && pair.to == cryptoCurrency);
      }
    }).toList();

    if (validProviders.isEmpty) {
      buySellQuotState = BuySellQuotFailed();
      return;
    }

    final result = await Future.wait<List<Quote>?>(validProviders.map((element) => element
        .fetchQuote(
          cryptoCurrency: cryptoCurrency,
          fiatCurrency: fiatCurrency,
          amount: amount,
          paymentType: selectedPaymentMethod?.paymentMethodType,
          isBuyAction: isBuyAction,
          walletAddress: wallet.walletAddresses.address,
          customPaymentMethodType: selectedPaymentMethod?.customPaymentMethodType,
        )
        .timeout(
          Duration(seconds: 10),
          onTimeout: () => null,
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

    if (isBuyAction) {
      validQuotes.sort((a, b) => b.payout.compareTo(a.payout));
    } else {
      validQuotes.sort((a, b) => a.payout.compareTo(b.payout));
    }

    final Set<String> addedProviders = {};
    final List<Quote> uniqueProviderQuotes = validQuotes.where((element) {
      if (addedProviders.contains(element.provider.title)) return false;
      addedProviders.add(element.provider.title);
      return true;
    }).toList();

    final List<Quote> successRateQuotes = validQuotes
        .where((element) =>
            element.provider is OnRamperBuyProvider &&
            element.recommendations.contains(ProviderRecommendation.successRate))
        .toList();

    for (final quote in successRateQuotes) {
      if (!uniqueProviderQuotes.contains(quote)) {
        uniqueProviderQuotes.add(quote);
      }
    }

    sortedRecommendedQuotes.addAll(uniqueProviderQuotes);

    sortedQuotes = ObservableList.of(
        validQuotes.where((element) => !uniqueProviderQuotes.contains(element)).toList());

    if (sortedRecommendedQuotes.isNotEmpty) {
      sortedRecommendedQuotes.first
        ..setIsBestRate = true
        ..recommendations.insert(0, ProviderRecommendation.bestRate);
      bestRateQuote = sortedRecommendedQuotes.first;

      sortedRecommendedQuotes.sort((a, b) {
        if (a.provider is OnRamperBuyProvider) return -1;
        if (b.provider is OnRamperBuyProvider) return 1;
        return 0;
      });

      selectedQuote = sortedRecommendedQuotes.first;
      sortedRecommendedQuotes.first.setIsSelected = true;
    }

    buySellQuotState = BuySellQuotLoaded();
  }

  @action
  Future<void> launchTrade(BuildContext context) async {
    final provider = selectedQuote!.provider;
    try {
      await provider.launchProvider(
        context: context,
        quote: selectedQuote!,
        amount: amount,
        isBuyAction: isBuyAction,
        cryptoCurrencyAddress: cryptoCurrencyAddress,
      );
    } catch (e) {
      if (e.toString().contains("403")) {
        buySellQuotState = BuySellQuotFailed(errorMessage: "Using Tor is not supported");
      } else {
        buySellQuotState =
            BuySellQuotFailed(errorMessage: "Something went wrong please try again later");
      }
    }
  }
}
