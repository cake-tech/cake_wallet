import 'package:cw_core/crypto_currency.dart';

class ExchangePair {
  ExchangePair({this.from, this.to, this.reverse = true});

  final CryptoCurrency from;
  final CryptoCurrency to;
  final bool reverse;
}
