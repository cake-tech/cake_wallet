import 'package:cake_wallet/entities/crypto_currency.dart';

String cryptoToString(CryptoCurrency crypto) {
  switch (crypto) {
    case CryptoCurrency.xmr:
      return 'XMR';
    case CryptoCurrency.btc:
      return 'BTC';
    default:
      return '';
  }
}