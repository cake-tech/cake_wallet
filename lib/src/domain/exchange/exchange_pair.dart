import 'package:cake_wallet/src/domain/common/crypto_currency.dart';

class ExchangePair {
  ExchangePair({this.from, this.to, this.reverse = true});

  final CryptoCurrency from;
  final CryptoCurrency to;
  final bool reverse;
}
