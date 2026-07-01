import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

const _fiatApiClearNetAuthority = 'fiat-api.cakewallet.com';
const _fiatApiOnionAuthority = 'kfkyguqtz5vcnbvar5pjgddkaeawbo4j3r4fj3e22k3tzqageplosiid.onion';
const _fiatApiPath = '/v2/rates';

Future<double> _fetchPrice(String crypto, String fiat, bool torOnly) async {

  final Map<String, String> queryParams = {
    'interval_count': '1',
    'base': crypto.split(".").first,
    'quote': fiat,
  };

  num price = 0.0;

  try {
    final onionUri = Uri.http(_fiatApiOnionAuthority, _fiatApiPath, queryParams);
    final clearnetUri = Uri.https(_fiatApiClearNetAuthority, _fiatApiPath, queryParams);

    final response = await ProxyWrapper().get(
      onionUri: onionUri,
      clearnetUri: torOnly ? onionUri : clearnetUri,
      headers: {
        "x-api-key": secrets.fiatApiKey,
      }
    );
    

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final results = responseJSON['results'] as Map<String, dynamic>;

    if (results.isNotEmpty) {
      price = results.values.first as num;
    }

    return price.toDouble();
  } catch (e) {
    return price.toDouble();
  }
}

/// Override specific [CryptoCurrency] to fix its price to the price of another
/// e.g. nDEPS should have the same price as DEPS, but only DEPS is tracked
CryptoCurrency _overrideCryptoCurrency(CryptoCurrency crypto) {
  if (crypto.title == CryptoCurrency.ndeps.title)
      return CryptoCurrency.deps;
    return crypto;
}

class FiatConversionService {
  static Future<double> fetchPrice({
    required CryptoCurrency crypto,
    required FiatCurrency fiat,
    required bool torOnly,
  }) async =>
      await _fetchPrice(_overrideCryptoCurrency(crypto).toString(), fiat.toString(), torOnly);
}
