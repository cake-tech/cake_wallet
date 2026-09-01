import "dart:convert";
import "dart:developer";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/buy/buy_exception.dart";
import "package:cake_wallet/buy/buy_provider.dart";
import "package:cake_wallet/buy/buy_provider_description.dart";
import "package:cake_wallet/buy/buy_quote.dart";
import "package:cake_wallet/buy/moonpay/moonpay_payment_methods.dart";
import "package:cake_wallet/buy/pairs_utils.dart";
import "package:cake_wallet/buy/payment_method.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/order/order.dart";
import "package:cake_wallet/order/order_source_description.dart";
import "package:cake_wallet/palette.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class MoonPayProvider extends BuyProvider {
  MoonPayProvider({
    required AppStore appStore,
    required super.wallet,
    super.isTestEnvironment = false,
  })  : baseSellUrl = isTestEnvironment ? _baseSellTestUrl : _baseSellProductUrl,
        baseBuyUrl = isTestEnvironment ? _baseBuyTestUrl : _baseBuyProductUrl,
        _appStore = appStore,
        super(
            hardwareWalletVM: null,
            supportedCryptoList: supportedCryptoToFiatPairs(
                notSupportedCrypto: _notSupportedCrypto, notSupportedFiat: _notSupportedFiat),
            supportedFiatList: supportedFiatToCryptoPairs(
                notSupportedFiat: _notSupportedFiat, notSupportedCrypto: _notSupportedCrypto));

  final AppStore _appStore;

  static const _baseSellTestUrl = "sell-sandbox.moonpay.com";
  static const _baseSellProductUrl = "sell.moonpay.com";
  static const _baseBuyTestUrl = "buy-staging.moonpay.com";
  static const _baseBuyProductUrl = "buy.moonpay.com";
  static const _cIdBaseUrl = "exchange-helper.cakewallet.com";
  static const _apiUrl = "https://api.moonpay.com";
  static const _baseUrl = "api.moonpay.com";
  static const _currenciesPath = "/v3/currencies";
  static const _buyQuote = "/buy_quote";
  static const _sellQuote = "/sell_quote";
  static const _paymentMethodsPath = "/api/moonpay/payment-methods";

  static const _transactionsSuffix = "/v1/transactions";

  static const List<CryptoCurrency> _notSupportedCrypto = [];
  static const List<FiatCurrency> _notSupportedFiat = [];

  static String get _exchangeHelperApiKey => secrets.exchangeHelperApiKey;

  static const Map<PaymentType, String> _moonPayPaymentMethodStrings = {
    PaymentType.creditCard: 'credit_debit_card',
    PaymentType.debitCard: 'credit_debit_card',
    PaymentType.ach: 'ach_bank_transfer',
    PaymentType.applePay: 'apple_pay',
    PaymentType.googlePay: 'google_pay',
    PaymentType.sepa: 'sepa_bank_transfer',
    PaymentType.paypal: 'paypal',
    PaymentType.sepaOpenBankingPayment: 'sepa_open_banking_payment',
    PaymentType.gbpOpenBankingPayment: 'gbp_open_banking_payment',
    PaymentType.lowCostAch: 'low_cost_ach',
    PaymentType.mobileWallet: 'mobile_wallet',
    PaymentType.pixInstantPayment: 'pix_instant_payment',
    PaymentType.yellowCardBankTransfer: 'yellow_card_bank_transfer',
    PaymentType.fiatBalance: 'fiat_balance',
    PaymentType.revolutPay: 'revolut_pay',
    PaymentType.moonpayCashApp: 'cash_app',
    PaymentType.moonpayBalance: 'moonpay_balance',
  };

  static final Map<String, PaymentType> _paymentTypeByMoonPayString = {
    for (final entry in _moonPayPaymentMethodStrings.entries) entry.value: entry.key,
  };

  String? normalizePaymentMethod(PaymentType paymentMethod) =>
      _moonPayPaymentMethodStrings[paymentMethod];

  PaymentType _getPaymentTypeByString(String? paymentMethod) =>
      _paymentTypeByMoonPayString[paymentMethod] ?? PaymentType.unknown;

  final String baseBuyUrl;
  final String baseSellUrl;

  @override
  String get providerDescription =>
      "MoonPay offers a fast and simple way to buy and sell cryptocurrencies";

  @override
  String get title => "MoonPay";

  @override
  String get lightIcon => "assets/images/moonpay_light.png";

  @override
  String get darkIcon => "assets/images/moonpay_dark.png";

  @override
  bool get isAggregator => false;

  String get _apiKey => isTestEnvironment ? secrets.moonPaySandboxApiKey : secrets.moonPayApiKey;

  String get currencyCode =>
      walletTypeToCryptoCurrency(wallet.type, chainId: wallet.chainId).title.toLowerCase();

  String get trackUrl => "$baseBuyUrl/transaction_receipt?transactionId=";

  Future<String> getMoonpaySignedQuery(String query) async {
    final uri =
        Uri.https(_cIdBaseUrl, "/api/moonpay", isTestEnvironment ? {"useSandbox": "true"} : null);

    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: {"Content-Type": "application/json", "x-api-key": _exchangeHelperApiKey},
      body: json.encode({"query": query}),
    );

    if (response.statusCode == 200) {
      printV(jsonDecode(response.body) as Map<String, dynamic>);
      return (jsonDecode(response.body) as Map<String, dynamic>)["query"] as String;
    } else {
      throw Exception(
        "Provider currently unavailable. Status: ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<List<MoonPayPaymentMethod>> fetchMoonPayPaymentMethods({
    required String currencyCode,
    String transactionType = "buy",
  }) async {
    final String? countryCode = FiatCurrency.tryDeserialize(raw: currencyCode)?.apiCountryCode;

    if (countryCode == null) {
      throw Exception("failed to determine country code for currency: $currencyCode");
    }

    final params = <String, String>{
      "currencyCode": currencyCode,
      "countryCode": countryCode,
      "transactionType": transactionType,
      if (countryCode == "USA") "stateOfResidence": "NY",
    };

    final uri = Uri.https(_cIdBaseUrl, _paymentMethodsPath, params);

    final response = await ProxyWrapper().get(
      clearnetUri: uri,
      headers: {
        "Accept": "application/json",
        "x-api-key": _exchangeHelperApiKey,
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 500) {
        throw Exception("failed to fetch payment methods. Status: 500 Internal Server Error");
      }
      throw Exception(
          "failed to fetch payment methods. Status: ${response.statusCode} ${response.body}");
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = decoded["payment-methods"] as List? ?? [];

    return list.map((e) => MoonPayPaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, CryptoCurrency cryptoCurrency, bool isBuyAction) async {
    final List<PaymentMethod> paymentMethods = [];

    try {
      final moonPayMethods = await fetchMoonPayPaymentMethods(
        currencyCode: fiatCurrency,
        transactionType: isBuyAction ? "buy" : "sell",
      );

      for (final method in moonPayMethods) {
        if (!method.active) {
          continue;
        }
        final paymentType = _getPaymentTypeByString(method.type);

        paymentMethods.add(PaymentMethod.fromMoonPayJson(
          method,
          paymentType,
        ),);
      }
    } catch (e) {
      printV("Error fetching payment methods: $e");
    }

    return paymentMethods;
  }

  @override
  Future<List<Quote>?> fetchQuote({
    required CryptoCurrency cryptoCurrency,
    required FiatCurrency fiatCurrency,
    required double amount,
    required bool isBuyAction,
    required String walletAddress,
    PaymentType? paymentType,
    String? customPaymentMethodType,
    String? countryCode,
  }) async {
    String? paymentMethod;

    if (paymentType != null && paymentType != PaymentType.all) {
      paymentMethod = normalizePaymentMethod(paymentType);
      paymentMethod ??= paymentType.name;
    }

    final action = isBuyAction ? "buy" : "sell";

    final formattedCryptoCurrency = _normalizeCurrency(cryptoCurrency);
    final baseCurrencyCode =
        isBuyAction ? fiatCurrency.name.toLowerCase() : cryptoCurrency.title.toLowerCase();

    final params = {
      "baseCurrencyCode": baseCurrencyCode,
      "baseCurrencyAmount": amount.toStringAsFixed(2),
      if (paymentMethod != null) "enabledPaymentMethods": paymentMethod,
      "areFeesIncluded": "false",
      'apiKey': "pk_live_JPGapObCLwMCCxREzYE8zvsRN06eppUf"
    };

    log("MoonPay: Fetching $action quote: ${isBuyAction ? formattedCryptoCurrency : fiatCurrency.name.toLowerCase()} -> ${isBuyAction ? baseCurrencyCode : formattedCryptoCurrency}, amount: $amount, paymentMethod: $paymentMethod");

    final quotePath = isBuyAction ? _buyQuote : _sellQuote;

    final path = "$_currenciesPath/$formattedCryptoCurrency$quotePath";
    final url = Uri.https(_baseUrl, path, params);
    try {
      final response = await ProxyWrapper().get(clearnetUri: url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Check if the response is for the correct fiat currency
        if (isBuyAction) {
          final fiatCurrencyCode = data['baseCurrencyCode'] as String?;
          if (fiatCurrencyCode == null || fiatCurrencyCode != fiatCurrency.name.toLowerCase())
            return null;
        } else {
          final quoteCurrency = data['quoteCurrency'] as Map<String, dynamic>?;
          if (quoteCurrency == null || quoteCurrency['code'] != fiatCurrency.name.toLowerCase())
            return null;
        }

        final paymentMethods = data['paymentMethod'] as String?;

        final quote =
            Quote.fromMoonPayJson(data, isBuyAction, _getPaymentTypeByString(paymentMethods ?? paymentMethod));

        quote.setFiatCurrency = fiatCurrency;
        quote.setCryptoCurrency = cryptoCurrency;

        return [quote];
      }
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData["message"] as String?;
        printV("Error fetching buy quote: $errorMessage");
        return null;
      } catch (e) {
        printV("Error parsing error response: $e");
        return null;
      }
    } catch (e) {
      printV("Exception while fetching buy quote: $e");
      return null;
    }
  }

  @override
  Future<void>? launchProvider(
      {required BuildContext context,
      required Quote quote,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    final Map<String, String> params = {
      "theme": _appStore.themeStore.currentTheme.type.name,
      "language": _appStore.settingsStore.languageCode,
      "colorCode": _appStore.themeStore.currentTheme.isDark
          ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
          : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
      "baseCurrencyCode": isBuyAction ? quote.fiatCurrency.name : quote.cryptoCurrency.name,
      "baseCurrencyAmount": amount.toStringAsFixed(2),
      "walletAddress": cryptoCurrencyAddress,
      "lockAmount": "false",
      "showAllCurrencies": "false",
      "showWalletAddressForm": "false",
      if (isBuyAction)
        "enabledPaymentMethods": normalizePaymentMethod(quote.paymentType) ??
            "credit_debit_card,apple_pay,google_pay,samsung_pay,sepa_bank_transfer,gbp_bank_transfer,gbp_open_banking_payment",
      if (!isBuyAction) 'refundWalletAddress': cryptoCurrencyAddress
    };

    if (isBuyAction) params['currencyCode'] = quote.cryptoCurrency.name;
    if (!isBuyAction) params['quoteCurrencyCode'] = quote.cryptoCurrency.name;

    try {
      final uri = await requestMoonPayUrl(
          walletAddress: cryptoCurrencyAddress,
          isBuyAction: isBuyAction,
          amount: amount.toString(),
          params: params);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Could not launch URL");
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) => AlertWithOneAction(
            alertTitle: 'MoonPay',
            alertContent: 'The MoonPay service is currently unavailable: $e',
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop(),
          ),
        );
      }
    }
  }

  Future<Uri> requestMoonPayUrl({
    required String walletAddress,
    required bool isBuyAction,
    required Map<String, String> params,
    String? amount,
  }) async {
    if (_apiKey.isNotEmpty) params["apiKey"] = _apiKey;

    final baseUrl = isBuyAction ? baseBuyUrl : baseSellUrl;
    final originalUri = Uri.https(baseUrl, "", params);

    final query = await getMoonpaySignedQuery("?${originalUri.query}");
    return Uri.parse(query);
  }

  Future<Order> findOrderById(String id) async {
    final url = _apiUrl + _transactionsSuffix + '/$id' + '?apiKey=' + _apiKey;
    final uri = Uri.parse(url);
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode != 200) {
      throw BuyException(title: providerDescription, content: 'Transaction $id is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status);
    final createdAtRaw = responseJSON['createdAt'] as String;
    final createdAt = DateTime.parse(createdAtRaw).toLocal();
    final amount = responseJSON['quoteCurrencyAmount'] as double;

    return Order(
        id: id,
        source: OrderSourceDescription.buy,
        buyProvider: BuyProviderDescription.moonPay,
        transferId: id,
        state: state,
        createdAt: createdAt,
        amount: amount.toString(),
        receiveAddress: wallet.walletAddresses.address,
        walletId: wallet.id);
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    if (currency.tag == 'POLY') {
      return '${currency.title.toLowerCase()}_polygon';
    }

    if (currency.tag == 'TRX') {
      return '${currency.title.toLowerCase()}_trx';
    }

    return currency.toString().toLowerCase();
  }
}
