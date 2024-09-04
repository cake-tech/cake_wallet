import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;

class OnRamperBuyProvider extends BuyProvider {
  OnRamperBuyProvider(this._settingsStore,
      {required WalletBase wallet, bool isTestEnvironment = false})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment, ledgerVM: null);

  static const _baseUrl = 'buy.onramper.com';
  static const _baseApiUrl = 'api.onramper.com';
  static const quotes = '/quotes';
  static const paymentTypes = '/payment-types';
  static const supported = '/supported';

  String get _apiKey => secrets.onramperApiKey;

  final SettingsStore _settingsStore;

  @override
  String get title => 'Onramper';

  @override
  String get providerDescription => S.current.onramper_option_description;

  @override
  String get lightIcon => 'assets/images/onramper_light.png';

  @override
  String get darkIcon => 'assets/images/onramper_dark.png';

  @override
  bool get isAggregator => true;

  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, String cryptoCurrency, bool isBuyAction) async {
    final params = {
      'fiatCurrency': fiatCurrency,
      'type': isBuyAction ? 'buy' : 'sell',
      'isRecurringPayment': 'false'
    };

    final url = Uri.https(_baseApiUrl, '$supported$paymentTypes/$fiatCurrency', params);

    try {
      final response =
          await http.get(url, headers: {'Authorization': _apiKey, 'accept': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> message = data['message'] as List<dynamic>;
        return message
            .map((item) => PaymentMethod.fromOnramperJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('Failed to fetch available payment types');
        return [];
      }
    } catch (e) {
      print('Failed to fetch available payment types: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getOnrampMetadata() async {
    final url = Uri.https(_baseApiUrl, '$supported/onramps/all');

    try {
      final response =
          await http.get(url, headers: {'Authorization': _apiKey, 'accept': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

        final List<dynamic> onramps = data['message'] as List<dynamic>;

        final Map<String, dynamic> result = {
          for (var onramp in onramps)
            (onramp['id'] as String): {
              'displayName': onramp['displayName'] as String,
              'svg': onramp['icons']['svg'] as String
            }
        };

        return result;
      } else {
        print('Failed to fetch onramp metadata');
        return {};
      }
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }

  @override
  Future<List<Quote>?> fetchQuote(
      {required String sourceCurrency,
      required String destinationCurrency,
      required double amount,
      required bool isBuyAction,
      required String walletAddress,
      PaymentType? paymentType,
      String? countryCode}) async {
    String? paymentMethod;
    if (paymentType != null) {
      paymentMethod = normalizePaymentMethod(paymentType);
      if (paymentMethod == null) paymentMethod = paymentType.name;
    }

    final actionType = isBuyAction ? 'buy' : 'sell';

    final normalizedSourceCurrency = _getNormalizeCryptoCurrency(sourceCurrency);
    final normalizedDestinationCurrency = _getNormalizeCryptoCurrency(destinationCurrency);

    final params = {
      'amount': amount.toString(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'uuid': 'acad3928-556f-48a1-a478-4e2ec76700cd',
      'clientName': 'CakeWallet',
      'type': actionType,
      'walletAddress': walletAddress,
      'isRecurringPayment': 'false',
      'input': 'source',
    };

    log('Onramper: Fetching $actionType quote: $normalizedSourceCurrency -> $normalizedDestinationCurrency, amount: $amount, paymentMethod: $paymentMethod');

    final url = Uri.https(
        _baseApiUrl, '$quotes/$normalizedSourceCurrency/$normalizedDestinationCurrency', params);
    final headers = {'Authorization': _apiKey, 'accept': 'application/json'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isEmpty) return null;

        List<Quote> validQuotes = [];

        final onrampMetadata = await getOnrampMetadata();

        for (var item in data) {
          if (item['errors'] != null) break;
          final quote = Quote.fromOnramperJson(
              item as Map<String, dynamic>, ProviderType.onramper, isBuyAction, onrampMetadata);
          quote.setSourceCurrency = sourceCurrency;
          quote.setDestinationCurrency = destinationCurrency;
          validQuotes.add(quote);
        }

        if (validQuotes.isEmpty) return null;

        return validQuotes;
      } else {
        print('Onramper: Failed to fetch rate');
        return null;
      }
    } catch (e) {
      print('Onramper: Failed to fetch rate $e');
      return null;
    }
  }

  Future<void>? launchProvider(
      {required BuildContext context,
      required Quote quote,
      required PaymentMethod? paymentMethod,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    final actionType = isBuyAction ? 'buy' : 'sell';
    final prefix = actionType == 'sell' ? actionType + '_' : '';

    String? paymentMethodString;
    if (paymentMethod != null) {
      paymentMethodString = normalizePaymentMethod(paymentMethod.paymentMethodType);
    } else {
      paymentMethodString = 'creditcard';
    }

    final primaryColor = getColorStr(Theme.of(context).primaryColor);
    final secondaryColor = getColorStr(Theme.of(context).colorScheme.background);
    final primaryTextColor = getColorStr(Theme.of(context).extension<CakeTextTheme>()!.titleColor);
    final secondaryTextColor =
        getColorStr(Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor);
    final containerColor = getColorStr(Theme.of(context).colorScheme.background);
    var cardColor = getColorStr(Theme.of(context).cardColor);

    if (_settingsStore.currentTheme.title == S.current.high_contrast_theme) {
      cardColor = getColorStr(Colors.white);
    }

    final networkName = wallet.currency.fullName?.toUpperCase().replaceAll(" ", "");

    final defaultFiat = isBuyAction
        ? _getNormalizeCryptoCurrency(quote.sourceCurrency)
        : _getNormalizeCryptoCurrency(quote.destinationCurrency);
    final defaultCrypto = isBuyAction
        ? _getNormalizeCryptoCurrency(quote.destinationCurrency)
        : _getNormalizeCryptoCurrency(quote.sourceCurrency);

    final uri = Uri.https(_baseUrl, '', {
      'apiKey': _apiKey,
      'mode': actionType,
      '${prefix}defaultFiat': defaultFiat,
      '${prefix}defaultCrypto': defaultCrypto,
      '${prefix}defaultAmount': amount.toString(),
      '${prefix}defaultPaymentMethod': paymentMethodString,
      'onlyOnramps': quote.rampId,
      'networkWallets': '${networkName}:${wallet.walletAddresses.address}',
      'supportSwap': "false",
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'containerColor': containerColor,
      'primaryTextColor': primaryTextColor,
      'secondaryTextColor': secondaryTextColor,
      'cardColor': cardColor,
    });

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch URL');
    }
  }

  String _getNormalizeCryptoCurrency(String currencyTitle) {
    //TODO: make it for all currencies
    switch (currencyTitle) {
      case 'LTC':
        return "LTC_LITECOIN";
      case 'XMR':
        return "XMR_MONERO";
      case 'BCH':
        return "BCH_BITCOINCASH";
      case 'XNO':
        return "XNO_NANO";
      case 'ADA':
        return "ADA_CARDANO";
      case 'DAI':
        return "DAI_ETHEREUM";
      case 'MATIC':
        return "MATIC_POLYGON";
      case 'TRX':
        return "TRX_TRON";
      default:
        return currencyTitle;
    }
  }

  String? normalizePaymentMethod(PaymentType paymentType) {
    switch (paymentType) {
      case PaymentType.bankTransfer:
        return 'banktransfer';
      case PaymentType.creditCard:
        return 'creditcard';
      case PaymentType.debitCard:
        return 'debitcard';
      case PaymentType.applePay:
        return 'applepay';
      case PaymentType.googlePay:
        return 'googlepay';
      case PaymentType.revolutPay:
        return 'revolutpay';
      case PaymentType.neteller:
        return 'neteller';
      case PaymentType.skrill:
        return 'skrill';
      case PaymentType.sepa:
        return 'sepabanktransfer';
      case PaymentType.sepaInstant:
        return 'sepainstant';
      case PaymentType.ach:
        return 'ach';
      case PaymentType.achInstant:
        return 'iach';
      case PaymentType.Khipu:
        return 'khipu';
      case PaymentType.palomaBanktTansfer:
        return 'palomabanktransfer';
      case PaymentType.ovo:
        return 'ovo';
      case PaymentType.zaloPay:
        return 'zalopay';
      case PaymentType.zaloBankTransfer:
        return 'zalobanktransfer';
      case PaymentType.gcash:
        return 'gcash';
      case PaymentType.imps:
        return 'imps';
      case PaymentType.dana:
        return 'dana';
      case PaymentType.ideal:
        return 'ideal';
      default:
        return null;
    }
  }

  String getColorStr(Color color) => color.value.toRadixString(16).replaceAll(RegExp(r'^ff'), "");
}
