import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

const _fiatApiClearNetAuthority = 'fiat-api.cakewallet.com';
const _fiatApiOnionAuthority = 'n4z7bdcmwk2oyddxvzaap3x2peqcplh3pzdy7tpkk5ejz5n4mhfvoxqd.onion';
const _fiatApiPath = '/v2/rates';

Future<double> _fetchPrice(Map<String, dynamic> args) async {
  final crypto = args['crypto'] as CryptoCurrency;
  final fiat = args['fiat'] as FiatCurrency;
  final torOnly = args['torOnly'] as bool;
  double price = 0.0;
  print("@@@@@@@@@@@@@@");
  print(crypto);
  print(fiat);
  print(torOnly);

  try {
    final uri = Uri.https(
      torOnly ? _fiatApiOnionAuthority : _fiatApiClearNetAuthority,
      _fiatApiPath,
      <String, String>{
        'interval_count': '1',
        'base': crypto.toString(),
        'quote': fiat.toString(),
      },
    );
    final response = await get(uri);

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final results = responseJSON['results'] as Map<String, dynamic>;

    if (results.isNotEmpty) {
      price = results.values.first as double;
    }
    print(price);

    return price;
  } catch (e) {
    return price;
  }
}

Future<double> _fetchPriceAsync(CryptoCurrency crypto, FiatCurrency fiat, bool torOnly) async =>
    compute(_fetchPrice, {'fiat': fiat, 'crypto': crypto, 'torOnly': torOnly});

class FiatConversionService {
  static Future<double> fetchPrice({
    required CryptoCurrency crypto,
    required FiatCurrency fiat,
    required bool torOnly,
  }) async =>
      await _fetchPriceAsync(crypto, fiat, torOnly);
}
