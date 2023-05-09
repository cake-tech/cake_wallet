import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

const _fiatApiClearNetAuthority = 'fiat-api.cakewallet.com';
const _fiatApiOnionAuthority = 'n4z7bdcmwk2oyddxvzaap3x2peqcplh3pzdy7tpkk5ejz5n4mhfvoxqd.onion';
const _fiatApiPath = '/v2/rates';

Future<double> _fetchPrice(Map<String, dynamic> args) async {
  final crypto = args['crypto'] as CryptoCurrency;
  final fiat = args['fiat'] as FiatCurrency;
  final torOnly = args['torOnly'] as bool;

  final Map<String, String> queryParams = {
    'interval_count': '1',
    'base': crypto.toString(),
    'quote': fiat.toString(),
    'key': secrets.fiatApiKey,
  };

  double price = 0.0;

  try {
    late final Uri uri;
    if (torOnly) {
      uri = Uri.http(_fiatApiOnionAuthority, _fiatApiPath, queryParams);
    } else {
      uri = Uri.https(_fiatApiClearNetAuthority, _fiatApiPath, queryParams);
    }

    final response = await get(uri);

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final results = responseJSON['results'] as Map<String, dynamic>;

    if (results.isNotEmpty) {
      price = results.values.first as double;
    }

    return price;
  } catch (e) {
    return price;
  }
}

Future<double> _fetchHistoricalPrice(Map<String, dynamic> args) async {
  final crypto = args['crypto'] as CryptoCurrency;
  final fiat = args['fiat'] as FiatCurrency;
  final torOnly = args['torOnly'] as bool;
  final date = args['date'] as DateTime;
  final intervalFromNow = DateTime.now().difference(date).inMinutes;

  final Map<String, String> queryParams = {
    'interval_count': '2',
    'base': crypto.toString(),
    'quote': fiat.toString(),
    'key': secrets.fiatApiKey,
    'interval_minutes': intervalFromNow.toString()
  };

  double price = 0.0;

  try {
    late final Uri uri;
    if (torOnly) {
      uri = Uri.http(_fiatApiOnionAuthority, _fiatApiPath, queryParams);
    } else {
      uri = Uri.https(_fiatApiClearNetAuthority, _fiatApiPath, queryParams);
    }

    final response = await get(uri);

    if (response.statusCode != 200) {
      return 0.0;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final errors = data['errors'] as Map<String, dynamic>;

    if (errors.isNotEmpty) {
      return 0.0;
    }

    final results = data['results'] as Map<String, dynamic>;

    if (results.isNotEmpty) {
      price = results.values.first as double;
    }
    print('results.key: ${results.keys.first} results.value: ${results.values.first}');

    return price;
  } catch (e) {
    print(e.toString());
    return 0.0;
  }
}

Future<double> _fetchPriceAsync(CryptoCurrency crypto, FiatCurrency fiat, bool torOnly) async =>
    compute(_fetchPrice, {'fiat': fiat, 'crypto': crypto, 'torOnly': torOnly});

Future<double> _fetchHistoricalAsync(
        CryptoCurrency crypto, FiatCurrency fiat, bool torOnly, DateTime date) async =>
    compute(
        _fetchHistoricalPrice, {'fiat': fiat, 'crypto': crypto, 'torOnly': torOnly, 'date': date});

class FiatConversionService {
  static Future<double> fetchPrice({
    required CryptoCurrency crypto,
    required FiatCurrency fiat,
    required bool torOnly,
  }) async =>
      await _fetchPriceAsync(crypto, fiat, torOnly);

  static Future<double> fetchHistoricalPrice({
    required CryptoCurrency crypto,
    required FiatCurrency fiat,
    required bool torOnly,
    required DateTime date,
  }) async =>
      await _fetchHistoricalAsync(crypto, fiat, torOnly, date);
}
