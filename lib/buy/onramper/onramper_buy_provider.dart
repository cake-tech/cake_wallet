import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/utils/device_info.dart';
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

  static const authorization = 'pk_prod_01HETEQF46GSK6BS5JWKDF31BT';

  static const quotes = '/quotes';

  static const paymentTypes = '/payment-types';

  static const supported = '/supported';

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

  String get _apiKey => secrets.onramperApiKey;

  String get _normalizeCryptoCurrency {
    switch (wallet.currency) {
      case CryptoCurrency.ltc:
        return "LTC_LITECOIN";
      case CryptoCurrency.xmr:
        return "XMR_MONERO";
      case CryptoCurrency.bch:
        return "BCH_BITCOINCASH";
      case CryptoCurrency.nano:
        return "XNO_NANO";
      default:
        return wallet.currency.title;
    }
  }

  String getColorStr(Color color) {
    return color.value.toRadixString(16).replaceAll(RegExp(r'^ff'), "");
  }

  Uri requestOnramperUrl(BuildContext context, bool? isBuyAction) {
    String primaryColor,
        secondaryColor,
        primaryTextColor,
        secondaryTextColor,
        containerColor,
        cardColor;

    primaryColor = getColorStr(Theme.of(context).primaryColor);
    secondaryColor = getColorStr(Theme.of(context).colorScheme.background);
    primaryTextColor = getColorStr(Theme.of(context).extension<CakeTextTheme>()!.titleColor);
    secondaryTextColor =
        getColorStr(Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor);
    containerColor = getColorStr(Theme.of(context).colorScheme.background);
    cardColor = getColorStr(Theme.of(context).cardColor);

    if (_settingsStore.currentTheme.title == S.current.high_contrast_theme) {
      cardColor = getColorStr(Colors.white);
    }

    final networkName = wallet.currency.fullName?.toUpperCase().replaceAll(" ", "");

    return Uri.https(_baseUrl, '', <String, dynamic>{
      'apiKey': _apiKey,
      'defaultCrypto': _normalizeCryptoCurrency,
      'sell_defaultCrypto': _normalizeCryptoCurrency,
      'networkWallets': '${networkName}:${wallet.walletAddresses.address}',
      'supportSwap': "false",
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'primaryTextColor': primaryTextColor,
      'secondaryTextColor': secondaryTextColor,
      'containerColor': containerColor,
      'cardColor': cardColor,
      'mode': isBuyAction == true ? 'buy' : 'sell',
    });
  }

  // Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
  //   final uri = requestOnramperUrl(context, isBuyAction);
  //   if (DeviceInfo.instance.isMobile) {
  //     Navigator.of(context).pushNamed(Routes.webViewPage, arguments: [title, uri]);
  //   } else {
  //     await launchUrl(uri);
  //   }
  // }

  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, String cryptoCurrency, bool isBuyAction) async {
    final params = {
      'fiatCurrency': fiatCurrency,
      'type': isBuyAction ? 'buy' : 'sell',
      'isRecurringPayment': 'false',
    };

    final path = '$supported$paymentTypes/$fiatCurrency';

    final url = Uri.https(_baseApiUrl, path, params);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': authorization,
          'accept': 'application/json',
        },
      );

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
      final response = await http.get(
        url,
        headers: {
          'Authorization': authorization,
          'accept': 'application/json',
        },
      );

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
    log('Onramper: Fetching $actionType quote: $sourceCurrency -> $destinationCurrency, amount: $amount');

    final path = '$quotes/$sourceCurrency/$destinationCurrency';
    final url = Uri.https(_baseApiUrl, path, params);
    final headers = {'Authorization': authorization, 'accept': 'application/json'};

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
      required PaymentMethod paymentMethod,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    final actionType = isBuyAction ? 'buy' : 'sell';
    final prefix = actionType == 'sell' ? actionType + '_' : '';

    final uri = Uri.https(_baseUrl, '', {
      'apiKey': _apiKey,
      'mode': actionType,
      '${prefix}defaultFiat': isBuyAction ? quote.sourceCurrency : quote.destinationCurrency,
      '${prefix}defaultCrypto': isBuyAction ? quote.destinationCurrency : quote.sourceCurrency,
      '${prefix}defaultAmount': amount.toString(),
      '${prefix}defaultPaymentMethod': normalizePaymentMethod(paymentMethod.paymentMethodType) ??
          paymentMethod.paymentMethodType.title ??
          'creditcard',
    });

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch URL');
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
}
