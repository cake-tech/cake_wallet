import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/pairs_utils.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:url_launcher/url_launcher.dart';

class KryptonimBuyProvider extends BuyProvider {
  KryptonimBuyProvider({required WalletBase wallet, bool isTestEnvironment = false})
      : super(
      wallet: wallet,
      isTestEnvironment: isTestEnvironment,
      hardwareWalletVM: null,
      supportedCryptoList: supportedCryptoToFiatPairs(
          notSupportedCrypto: _notSupportedCrypto, notSupportedFiat: _notSupportedFiat),
      supportedFiatList: supportedFiatToCryptoPairs(
          notSupportedFiat: _notSupportedFiat, notSupportedCrypto: _notSupportedCrypto));

  static const _isProduction = true;

  static const _baseUrl = _isProduction ? 'app.kryptonim.com' : 'intg-api.kryptonim.com';
  static const _baseWidgetUrl = _isProduction ? 'buy.kryptonim.com' : 'intg.kryptonim.com';
  static const _quotePath = '/v2/ramp/buy/quotes';
  static const _merchantId = 'a70fe053';

  static String get _kryptonimApiKey => secrets.kryptonimApiKey;

  static const List<CryptoCurrency> _notSupportedCrypto = [];
  static const List<FiatCurrency> _notSupportedFiat = [];

  @override
  String get title => 'Kryptonim';

  @override
  String get providerDescription => 'Kryptonim Buy Provider';

  @override
  String get lightIcon => 'assets/images/kryptonim_light.png';

  @override
  String get darkIcon => 'assets/images/kryptonim_dark.png';

  @override
  bool get isAggregator => false;

  Future<Map<String, dynamic>> getExchangeRates(
      {required CryptoCurrency cryptoCurrency,
      required String fiatCurrency,
      required double amount}) async {
    final url = Uri.https(_baseUrl, _quotePath, {'m': _merchantId});

    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': _kryptonimApiKey,
    };

    final body = jsonEncode({
      'amount': amount,
      'currency': fiatCurrency,
      'converted_currency': cryptoCurrency.title,
      'blockchain': _normalizeBlockChain(cryptoCurrency),
      'quote_currency': fiatCurrency,
    });

    try {
      final response = await ProxyWrapper().post(
        clearnetUri: url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 401) {
        
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  @override
  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, CryptoCurrency cryptoCurrency, bool isBuyAction) async {

    final data = await getExchangeRates(
      cryptoCurrency: cryptoCurrency,
      fiatCurrency: fiatCurrency,
      amount: 100.0,
    );

    if (data.isEmpty || !data.containsKey('data')) return [];

    final paymentMethods = (data['data'] as List<dynamic>)
        .map((e) => PaymentMethod.fromKryptonimJson(e as Map<String, dynamic>))
        .toList();

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
    log('Kryptonim: Fetching quote: ${isBuyAction ? cryptoCurrency : fiatCurrency} -> ${isBuyAction ? fiatCurrency : cryptoCurrency}, amount: $amount');

    final data = await getExchangeRates(
      cryptoCurrency: cryptoCurrency,
      fiatCurrency: fiatCurrency.toString(),
      amount: amount,
    );

    if (!data.containsKey('data') || (data['data'] as List).isEmpty) {
      return null;
    }

    final quotesList = data['data'] as List<dynamic>;

    Map<String, dynamic>? selectedPaymentMethod;

    if (paymentType == PaymentType.all || paymentType == null) {
      selectedPaymentMethod = quotesList.first as Map<String, dynamic>;
    } else {
      for (var quote in quotesList) {
        final quotePaymentType = PaymentMethod.getPaymentTypeId(quote['payment_method'] as String?);
        if (quotePaymentType == paymentType) {
          selectedPaymentMethod = quote as Map<String, dynamic>;
          break;
        }
      }
    }

    if (selectedPaymentMethod == null) {
      return null;
    }

    final selectedPaymentType =
        PaymentMethod.getPaymentTypeId(selectedPaymentMethod['payment_method'] as String?);
    final quote = Quote.fromKryptonimJson(selectedPaymentMethod, isBuyAction, selectedPaymentType ?? PaymentType.unknown);

    quote.setFiatCurrency = fiatCurrency;
    quote.setCryptoCurrency = cryptoCurrency;

    return [quote];
  }

  @override
  Future<void>? launchProvider(
      {required BuildContext context,
      required Quote quote,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    final params = {
      'amount': amount.toInt().toString(),
      'currency': quote.fiatCurrency.name,
      'convertedCurrency': quote.cryptoCurrency.title,
      'blockchain': _normalizeBlockChain(quote.cryptoCurrency),
      'address': cryptoCurrencyAddress,
      'paymentMethod': normalizePaymentMethod(quote.paymentType),
    };

    final uri = Uri.https(_baseWidgetUrl, '/redirect-form', params);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
            alertTitle: "Kryptonim",
            alertContent: "Payment provider is unavailable: $e",
            buttonText: "OK",
            buttonAction: () => Navigator.of(context).pop(),
          );
        },
      );
    }
  }

  String normalizePaymentMethod(PaymentType paymentType) {
    switch (paymentType) {
      case PaymentType.bankTransfer:
        return 'bank';
      case PaymentType.creditCard:
      case PaymentType.debitCard:
        return 'card';
      default:
        return paymentType.name.toLowerCase();
    }
  }

  String _normalizeBlockChain(CryptoCurrency cur) {
    String? blockchain = switch (cur.tag) {
      'ETH' => 'Ethereum',
      'POL' => 'Polygon',
      'AVAXC' => 'Avalanche',
      'SOL' => 'Solana',
      _ => null,
    };

    if (blockchain == null) {
      blockchain = switch (cur) {
        CryptoCurrency.btc => 'Bitcoin',
        CryptoCurrency.ltc => 'Litecoin',
        CryptoCurrency.eth => 'Ethereum',
        CryptoCurrency.maticpoly => 'Matic',
        _ => null,
      };
    }

    return blockchain ?? cur.fullName ?? '';
  }
}
