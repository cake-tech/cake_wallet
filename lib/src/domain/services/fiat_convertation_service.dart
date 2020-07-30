import 'dart:async';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/fetch_price.dart';

class FiatConvertationService {
  Future<double> getPrice({CryptoCurrency crypto, FiatCurrency fiat}) async {
    return await fetchPriceFor(crypto: crypto, fiat: fiat);
  }
}