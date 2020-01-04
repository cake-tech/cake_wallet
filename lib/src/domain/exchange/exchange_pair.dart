import 'package:cake_wallet/src/domain/common/crypto_currency.dart';

class ExchangePair {
  final CryptoCurrency from;
  final CryptoCurrency to;
  final bool reverse;

  ExchangePair({this.from, this.to, this.reverse = true});
}