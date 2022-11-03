import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

const fiatApiAuthority = 'fiat-api.cakewallet.com';
const fiatApiPath = '/v1/rates';

Future<double> _fetchPrice(Map<String, dynamic> args) async {
  final crypto = args['crypto'] as CryptoCurrency;
  final fiat = args['fiat'] as FiatCurrency;
  double price = 0.0;

  try {
    final fiatStringified = fiat.toString();
    final uri = Uri.https(fiatApiAuthority, fiatApiPath,
        <String, String>{'convert': fiatStringified});
    final response = await get(uri);

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final data = responseJSON['data'] as List<dynamic>;

    for (final item in data) {
      if (item['symbol'] == crypto.title) {
        price = item['quote'][fiatStringified]['price'] as double;
        break;
      }
    }

    return price;
  } catch (e) {
    return price;
  }
}

Future<double> _fetchPriceAsync(
        CryptoCurrency crypto, FiatCurrency fiat) async =>
    compute(_fetchPrice, {'fiat': fiat, 'crypto': crypto});

class FiatConversionService {
  static Future<double> fetchPrice(
          CryptoCurrency crypto, FiatCurrency fiat) async =>
      await _fetchPriceAsync(crypto, fiat);
}
