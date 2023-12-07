import 'dart:io';

import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

const _fiatApiClearNetAuthority = 'fiat-api.cakewallet.com';
const _fiatApiOnionAuthority = 'n4z7bdcmwk2oyddxvzaap3x2peqcplh3pzdy7tpkk5ejz5n4mhfvoxqd.onion';
const _fiatApiPath = '/v2/rates';

Future<double> _fetchPrice(Map<String, dynamic> args) async {
  final crypto = args['crypto'] as String;
  final fiat = args['fiat'] as String;
  final torOnly = args['apiMode'] as String == FiatApiMode.torOnly.toString();

  final Map<String, String> queryParams = {
    'interval_count': '1',
    'base': crypto.split(".").first,
    'quote': fiat,
    'key': secrets.fiatApiKey,
  };

  num price = 0.0;

  try {
    final Uri onionUri = Uri.http(_fiatApiOnionAuthority, _fiatApiPath, queryParams);
    final Uri clearnetUri = Uri.https(_fiatApiClearNetAuthority, _fiatApiPath, queryParams);

    HttpClient client = await ProxyWrapper.instance.getProxyInstance();
    late HttpClientResponse response;
    late String responseBody;
    
    try {
      final request = await client.getUrl(onionUri);
      response = await request.close();
      responseBody = await utf8.decodeStream(response);
    } catch (e) {
      if (!torOnly) {
        final request = await client.getUrl(clearnetUri);
        response = await request.close();
        responseBody = await utf8.decodeStream(response);
      }
    }

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(responseBody) as Map<String, dynamic>;
    final results = responseJSON['results'] as Map<String, dynamic>;

    if (results.isNotEmpty) {
      price = results.values.first as num;
    }

    return price.toDouble();
  } catch (e) {
    return price.toDouble();
  }
}

Future<double> _fetchPriceAsync(
        CryptoCurrency crypto, FiatCurrency fiat, FiatApiMode apiMode) async =>
    _fetchPrice({
      'fiat': fiat.toString(),
      'crypto': crypto.toString(),
      'apiMode': apiMode.toString(),
    });

class FiatConversionService {
  static Future<double> fetchPrice({
    required CryptoCurrency crypto,
    required FiatCurrency fiat,
    required FiatApiMode apiMode,
  }) async =>
      await _fetchPriceAsync(crypto, fiat, apiMode);
}
