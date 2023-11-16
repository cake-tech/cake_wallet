import 'package:cw_core/crypto_currency.dart';

class ExchangePair {
  ExchangePair({required this.from, required this.to, this.reverse = true});

  final CryptoCurrency from;
  final CryptoCurrency to;
  final bool reverse;
}
