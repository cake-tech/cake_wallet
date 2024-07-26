import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_exception.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';

class MoonPayProvider extends BuyProvider {
  MoonPayProvider({
    required SettingsStore settingsStore,
    required WalletBase wallet,
    bool isTestEnvironment = false,
  })  : baseSellUrl = isTestEnvironment ? _baseSellTestUrl : _baseSellProductUrl,
        baseBuyUrl = isTestEnvironment ? _baseBuyTestUrl : _baseBuyProductUrl,
        this._settingsStore = settingsStore,
        super(wallet: wallet, isTestEnvironment: isTestEnvironment, ledgerVM: null);

  final SettingsStore _settingsStore;

  static const _baseSellTestUrl = 'sell-sandbox.moonpay.com';
  static const _baseSellProductUrl = 'sell.moonpay.com';
  static const _baseBuyTestUrl = 'buy-staging.moonpay.com';
  static const _baseBuyProductUrl = 'buy.moonpay.com';
  static const _cIdBaseUrl = 'exchange-helper.cakewallet.com';
  static const _apiUrl = 'https://api.moonpay.com';
  static const _baseUrl = 'api.moonpay.com';
  static const _buyPath = '/v3/currencies';
  static const _buyQuote = '/buy_quote';
  static const _sellQuote = '/sell_quote';

  @override
  String get providerDescription =>
      'MoonPay offers a fast and simple way to buy and sell cryptocurrencies';

  @override
  String get title => 'MoonPay';

  @override
  String get lightIcon => 'assets/images/moonpay_light.png';

  @override
  String get darkIcon => 'assets/images/moonpay_dark.png';

  @override
  bool get isAggregator => false;

  static String themeToMoonPayTheme(ThemeBase theme) {
    switch (theme.type) {
      case ThemeType.bright:
      case ThemeType.light:
        return 'light';
      case ThemeType.dark:
        return 'dark';
    }
  }

  static String get _apiKey => secrets.moonPayApiKey;

  final String baseBuyUrl;
  final String baseSellUrl;

  String get currencyCode => walletTypeToCryptoCurrency(wallet.type).title.toLowerCase();

  String get trackUrl => baseBuyUrl + '/transaction_receipt?transactionId=';

  static String get _exchangeHelperApiKey => secrets.exchangeHelperApiKey;

  Future<String> getMoonpaySignature(String query) async {
    final uri = Uri.https(_cIdBaseUrl, "/api/moonpay");

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _exchangeHelperApiKey,
      },
      body: json.encode({'query': query}),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['signature'] as String;
    } else {
      throw Exception(
          'Provider currently unavailable. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<Uri> requestSellMoonPayUrl({
    required CryptoCurrency currency,
    required String refundWalletAddress,
    required SettingsStore settingsStore,
    Map<String, String>? extraParams,
  }) async {
    final params = extraParams ??
        {
          'theme': themeToMoonPayTheme(settingsStore.currentTheme),
          'language': settingsStore.languageCode,
          'colorCode': settingsStore.currentTheme.type == ThemeType.dark
              ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
              : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
          'defaultCurrencyCode': _normalizeCurrency(currency),
          'refundWalletAddress': refundWalletAddress,
        };

    if (_apiKey.isNotEmpty) {
      params['apiKey'] = _apiKey;
    }

    final originalUri = Uri.https(
      baseSellUrl,
      '',
      params,
    );

    if (isTestEnvironment) {
      return originalUri;
    }

    final signature = await getMoonpaySignature('?${originalUri.query}');

    final query = Map<String, dynamic>.from(originalUri.queryParameters);
    query['signature'] = signature;
    final signedUri = originalUri.replace(queryParameters: query);
    return signedUri;
  }

  // BUY:
  static const _currenciesSuffix = '/v3/currencies';
  static const _quoteSuffix = '/buy_quote';
  static const _transactionsSuffix = '/v1/transactions';
  static const _ipAddressSuffix = '/v4/ip_address';

  Future<Uri> requestBuyMoonPayUrl({
    required CryptoCurrency currency,
    required SettingsStore settingsStore,
    required String walletAddress,
    String? amount,
    Map<String, String>? extraParams,
  }) async {
    final params = extraParams ??
        {
          'theme': themeToMoonPayTheme(settingsStore.currentTheme),
          'language': settingsStore.languageCode,
          'colorCode': settingsStore.currentTheme.type == ThemeType.dark
              ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
              : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
          'defaultCurrencyCode': _normalizeCurrency(currency),
          'baseCurrencyCode': _normalizeCurrency(currency),
          'baseCurrencyAmount': amount ?? '0',
          'currencyCode': currencyCode,
          'walletAddress': walletAddress,
          'lockAmount': 'false',
          'showAllCurrencies': 'false',
          'showWalletAddressForm': 'false',
          'enabledPaymentMethods':
              'credit_debit_card,apple_pay,google_pay,samsung_pay,sepa_bank_transfer,gbp_bank_transfer,gbp_open_banking_payment',
        };

    if (_apiKey.isNotEmpty) {
      params['apiKey'] = _apiKey;
    }

    final originalUri = Uri.https(
      baseBuyUrl,
      '',
      params,
    );

    if (isTestEnvironment) {
      return originalUri;
    }

    final signature = await getMoonpaySignature('?${originalUri.query}');
    final query = Map<String, dynamic>.from(originalUri.queryParameters);
    query['signature'] = signature;
    final signedUri = originalUri.replace(queryParameters: query);
    return signedUri;
  }

  Future<BuyAmount> calculateAmount(String amount, String sourceCurrency) async {
    final url = _apiUrl +
        _currenciesSuffix +
        '/$currencyCode' +
        _quoteSuffix +
        '/?apiKey=' +
        _apiKey +
        '&baseCurrencyAmount=' +
        amount +
        '&baseCurrencyCode=' +
        sourceCurrency.toLowerCase();
    final uri = Uri.parse(url);
    final response = await get(uri);

    if (response.statusCode != 200) {
      throw BuyException(title: providerDescription, content: 'Quote is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final sourceAmount = responseJSON['totalAmount'] as double;
    final destAmount = responseJSON['quoteCurrencyAmount'] as double;
    final minSourceAmount = responseJSON['baseCurrency']['minAmount'] as int;

    return BuyAmount(
        sourceAmount: sourceAmount, destAmount: destAmount, minAmount: minSourceAmount);
  }

  Future<Order> findOrderById(String id) async {
    final url = _apiUrl + _transactionsSuffix + '/$id' + '?apiKey=' + _apiKey;
    final uri = Uri.parse(url);
    final response = await get(uri);

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
        provider: BuyProviderDescription.moonPay,
        transferId: id,
        state: state,
        createdAt: createdAt,
        amount: amount.toString(),
        receiveAddress: wallet.walletAddresses.address,
        walletId: wallet.id);
  }

  static Future<bool> onEnabled() async {
    final url = _apiUrl + _ipAddressSuffix + '?apiKey=' + _apiKey;
    var isBuyEnable = false;
    final uri = Uri.parse(url);
    final response = await get(uri);

    try {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      isBuyEnable = responseJSON['isBuyAllowed'] as bool;
    } catch (e) {
      isBuyEnable = false;
      print(e.toString());
    }

    return isBuyEnable;
  }

  @override
  Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
    try {
      late final Uri uri;
      if (isBuyAction ?? true) {
        uri = await requestBuyMoonPayUrl(
          currency: wallet.currency,
          walletAddress: wallet.walletAddresses.address,
          settingsStore: _settingsStore,
        );
      } else {
        uri = await requestSellMoonPayUrl(
          currency: wallet.currency,
          refundWalletAddress: wallet.walletAddresses.address,
          settingsStore: _settingsStore,
        );
      }

      if (await canLaunchUrl(uri)) {
        if (DeviceInfo.instance.isMobile) {
          Navigator.of(context).pushNamed(Routes.webViewPage, arguments: ['MoonPay', uri]);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
              alertTitle: 'MoonPay',
              alertContent: 'The MoonPay service is currently unavailable: $e',
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop(),
            );
          },
        );
      }
    }
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    if (currency == CryptoCurrency.maticpoly) {
      return "MATIC_POLYGON";
    }

    return currency.toString().toLowerCase();
  }

  Future<Map<String, dynamic>> fetchFiatCredentials(
      String fiatCurrency, String cryptocurrency, String? paymentMethod) async {
    final params = {'baseCurrencyCode': fiatCurrency.toLowerCase(), 'apiKey': _apiKey};

    if (paymentMethod != null) params['paymentMethod'] = paymentMethod;

    final path = '$_buyPath/${cryptocurrency.toLowerCase()}/limits';
    final url = Uri.https(_baseUrl, path, params);

    try {
      final response = await get(url, headers: {'accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('MoonPay does not support fiat: $fiatCurrency');
        return {};
      }
    } catch (e) {
      print('MoonPay Error fetching fiat currencies: $e');
      return {};
    }
  }

  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, String cryptoCurrency, bool isBuyAction) async {
    final List<PaymentMethod> paymentMethods = [];

    if (isBuyAction) {
      final fiatBuyCredentials = await fetchFiatCredentials(fiatCurrency, cryptoCurrency, null);
      if (fiatBuyCredentials.isNotEmpty) {
        final paymentMethod = fiatBuyCredentials['paymentMethods'] as String?;
        paymentMethods
            .add(PaymentMethod.fromMoonPayJson(fiatBuyCredentials, getPaymentType(paymentMethod)));
        return paymentMethods;
      }
    } else {
      //final assetBuyCredentials = await fetchAssets(assetsName: [fiatCurrency]);
      paymentMethods;
    }

    return paymentMethods;
  }

  Future<Quote?> fetchQuote(
      {required String sourceCurrency,
      required String destinationCurrency,
      required double amount,
      required PaymentType paymentType,
      required bool isBuyAction,
      required String walletAddress,
      String? countryCode}) async {
    var paymentMethod = normalizePaymentMethod(paymentType);
    if (paymentMethod == null) paymentMethod = paymentType.name;

    final action = isBuyAction ? 'buy' : 'sell';

    final params = {
      'baseCurrencyCode': sourceCurrency.toLowerCase(),
      'baseCurrencyAmount': amount.toString(),
      'amount': amount.toString(),
      'paymentMethod': paymentMethod,
      'areFeesIncluded': 'false',
      'apiKey': _apiKey,
    };

    log('MoonPay: Fetching $action quote: $sourceCurrency -> $destinationCurrency, amount: $amount, paymentMethod: $paymentMethod');

    final quotePath = isBuyAction ? _buyQuote : _sellQuote;
    final currency = (isBuyAction ? destinationCurrency : sourceCurrency).toLowerCase();

    final path = '$_buyPath/$currency$quotePath';
    final url = Uri.https(_baseUrl, path, params);

    try {
      final response = await get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final quote = Quote.fromMoonPayJson(data, ProviderType.moonpay, isBuyAction);

        quote.setSourceCurrency = sourceCurrency;
        quote.setDestinationCurrency = destinationCurrency;

        return quote;
      } else {
        print('Moon Pay: Error fetching buy quote: ');
        return null;
      }
    } catch (e) {
      print('Moon Pay: Error fetching buy quote: $e');
      return null;
    }
  }

  @override
  Future<void>? launchTrade(
      {required BuildContext context,
      required Quote quote,
      required PaymentMethod paymentMethod,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    final currency =
        CryptoCurrency.fromString(isBuyAction ? quote.destinationCurrency : quote.sourceCurrency);

    final Map<String, String> extraParams = {
      'theme': themeToMoonPayTheme(_settingsStore.currentTheme),
      'language': _settingsStore.languageCode,
      'colorCode': _settingsStore.currentTheme.type == ThemeType.dark
          ? '#${Palette.blueCraiola.value.toRadixString(16).substring(2, 8)}'
          : '#${Palette.moderateSlateBlue.value.toRadixString(16).substring(2, 8)}',
      'baseCurrencyCode': isBuyAction ? quote.sourceCurrency : quote.sourceCurrency,
      'baseCurrencyAmount': amount.toString(),
      'walletAddress': cryptoCurrencyAddress,
      'lockAmount': 'false',
      'showAllCurrencies': 'false',
      'showWalletAddressForm': 'false',
      'enabledPaymentMethods': normalizePaymentMethod(paymentMethod.paymentMethodType) ??
          paymentMethod.paymentMethodType.title ??
          'credit_debit_card',
    };

    if (isBuyAction) extraParams['currencyCode'] = quote.destinationCurrency;
    if (!isBuyAction) extraParams['quoteCurrencyCode'] = quote.destinationCurrency;

    try {
      late final Uri uri;
      if (isBuyAction) {
        uri = await requestBuyMoonPayUrl(
          currency: currency,
          walletAddress: cryptoCurrencyAddress,
          settingsStore: _settingsStore,
          extraParams: extraParams,
        );
      } else {
        uri = await requestSellMoonPayUrl(
          currency: currency,
          refundWalletAddress: cryptoCurrencyAddress,
          settingsStore: _settingsStore,
          extraParams: extraParams,
        );
      }

      if (await canLaunchUrl(uri)) {
        if (DeviceInfo.instance.isMobile) {
          Navigator.of(context).pushNamed(Routes.webViewPage, arguments: ['MoonPay', uri]);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
              alertTitle: 'MoonPay',
              alertContent: 'The MoonPay service is currently unavailable: $e',
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop(),
            );
          },
        );
      }
    }
  }

  String? normalizePaymentMethod(PaymentType paymentMethod) {
    switch (paymentMethod) {
      case PaymentType.creditCard:
        return 'credit_debit_card';
      case PaymentType.debitCard:
        return 'credit_debit_card';
      case PaymentType.ach:
        return 'ach_bank_transfer';
      case PaymentType.applePay:
        return 'apple_pay';
      case PaymentType.googlePay:
        return 'google_pay';
      case PaymentType.sepa:
        return 'sepa_bank_transfer';
      case PaymentType.paypal:
        return 'paypal';
      case PaymentType.sepaOpenBankingPayment:
        return 'sepa_open_banking_payment';
      case PaymentType.gbpOpenBankingPayment:
        return 'gbp_open_banking_payment';
      case PaymentType.lowCostAch:
        return 'low_cost_ach';
      case PaymentType.mobileWallet:
        return 'mobile_wallet';
      case PaymentType.pixInstantPayment:
        return 'pix_instant_payment';
      case PaymentType.yellowCardBankTransfer:
        return 'yellow_card_bank_transfer';
      case PaymentType.fiatBalance:
        return 'fiat_balance';
      default:
        return null;
    }
  }

  PaymentType getPaymentType(String? paymentMethod) {
    switch (paymentMethod) {
      case 'ach_bank_transfer':
        return PaymentType.ach;
      case 'apple_pay':
        return PaymentType.applePay;
      case 'credit_debit_card':
        return PaymentType.creditCard;
      case 'fiat_balance':
        return PaymentType.fiatBalance;
      case 'gbp_open_banking_payment':
        return PaymentType.gbpOpenBankingPayment;
      case 'google_pay':
        return PaymentType.googlePay;
      case 'low_cost_ach':
        return PaymentType.lowCostAch;
      case 'mobile_wallet':
        return PaymentType.mobileWallet;
      case 'paypal':
        return PaymentType.paypal;
      case 'pix_instant_payment':
        return PaymentType.pixInstantPayment;
      case 'sepa_bank_transfer':
        return PaymentType.sepa;
      case 'sepa_open_banking_payment':
        return PaymentType.sepaOpenBankingPayment;
      case 'yellow_card_bank_transfer':
        return PaymentType.yellowCardBankTransfer;
      default:
        return PaymentType.unknown;
    }
  }
}
