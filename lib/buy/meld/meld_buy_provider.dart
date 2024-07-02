import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MeldBuyProvider extends BuyProvider {
  MeldBuyProvider({required WalletBase wallet, bool isTestEnvironment = false})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment, ledgerVM: null);

  static String get _testApiKey => secrets.meldTestApiKey;

  static const _basTestUrl = 'api-sb.meld.io';
  static const _providersProperties = '/service-providers/properties';
  static const _paymentMethodsPath = '/payment-methods';
  static const _quotePath = '/payments/crypto/quote';

  @override
  String get title => 'Meld';

  @override
  String get providerDescription => 'Meld Buy Provider Description';

  @override
  String get lightIcon => 'assets/images/meld_logo.svg';

  @override
  String get darkIcon => 'assets/images/meld_logo.svg';

  @override
  bool get isAggregator => true;

  @override
  Future<List<PaymentMethod>> getAvailablePaymentTypes(String fiatCurrency, String type) async {
    final params = {
      'fiatCurrencies': fiatCurrency,
      'statuses': 'LIVE,RECENTLY_ADDED,BUILDING',
    };

    final path = '$_providersProperties$_paymentMethodsPath';

    final url = Uri.https(_basTestUrl, path, params);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _testApiKey,
          'Meld-Version': '2023-12-19',
          'accept': 'application/json',
          'content-type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final paymentMethods =
            data.map((e) => PaymentMethod.fromMeldJson(e as Map<String, dynamic>)).toList();
        return paymentMethods;
      } else {
        print('Failed to fetch Meld payment types');
        return List<PaymentMethod>.empty();
      }
    } catch (e) {
      print('Failed to fetch Meld payment types: $e');
      return List<PaymentMethod>.empty();
    }
  }

  Future<Quote?> fetchQuote({
    required String sourceCurrency,
    required String destinationCurrency,
    required int amount,
    required PaymentType paymentType,
    required String type,
    required String walletAddress,
  }) async {
    final url = Uri.https(_basTestUrl, _quotePath);
    final headers = {
      'Authorization': _testApiKey,
      'Meld-Version': '2023-12-19',
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    final body = jsonEncode({
      'countryCode': 'US',
      'destinationCurrencyCode': destinationCurrency,
      'sourceAmount': amount,
      'sourceCurrencyCode': sourceCurrency,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final quote = Quote.fromMeldJson(data, ProviderType.meld);

        quote.setSourceCurrency = sourceCurrency;
        quote.setDestinationCurrency = destinationCurrency;

        return quote;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching buy quote: $e');
      return null;
    }
  }

  @override
  Future<void> launchProvider(BuildContext context, bool? isBuyAction) {
    // TODO: implement launchProvider
    throw UnimplementedError();
  }
}
