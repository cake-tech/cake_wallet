import 'dart:convert';
import 'package:http/http.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/currency_formatter.dart';

const fiatApiAuthority = 'fiat-api.cakewallet.com';
const fiatApiPath = '/v1/rates';

Future<double> fetchPriceFor({CryptoCurrency crypto, FiatCurrency fiat}) async {
  double price = 0.0;

  try {
    final fiatStringified = fiat.toString();
    final uri =
        Uri.https(fiatApiAuthority, fiatApiPath, {'convert': fiatStringified});
    final response = await get(uri.toString());

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(response.body);
    final data = responseJSON['data'];

    for (final item in data) {
      if (item['symbol'] == cryptoToString(crypto)) {
        price = item['quote'][fiatStringified]['price'];
        break;
      }
    }

    return price;
  } catch (e) {
    return price;
  }
}
