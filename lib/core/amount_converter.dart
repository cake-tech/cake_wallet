import 'package:intl/intl.dart';
import 'package:cw_core/crypto_currency.dart';

class AmountConverter {
  static const _moneroAmountLength = 12;
  static const _moneroAmountDivider = 1000000000000;
  static const _wowneroAmountLength = 11;
  static const _wowneroAmountDivider = 100000000000;
  static const _litecoinAmountDivider = 100000000;
  static const _ethereumAmountDivider = 1000000000000000000;
  static const _dashAmountDivider = 100000000;
  static const _bitcoinCashAmountDivider = 100000000;
  static const _bitcoinAmountDivider = 100000000;
  static const _bitcoinAmountLength = 8;
  static final _bitcoinAmountFormat = NumberFormat()
    ..maximumFractionDigits = _bitcoinAmountLength
    ..minimumFractionDigits = 1;
  static final _moneroAmountFormat = NumberFormat()
    ..maximumFractionDigits = _moneroAmountLength
    ..minimumFractionDigits = 1;
  static final _wowneroAmountFormat = NumberFormat()
    ..maximumFractionDigits = _wowneroAmountLength
    ..minimumFractionDigits = 1;

  static double amountIntToDouble(CryptoCurrency cryptoCurrency, int amount) {
    switch (cryptoCurrency) {
      case CryptoCurrency.xmr:
        return _moneroAmountToDouble(amount);
      case CryptoCurrency.btc:
        return _bitcoinAmountToDouble(amount);
      case CryptoCurrency.wow:
        return _wowneroAmountToDouble(amount);
      case CryptoCurrency.bch:
        return _bitcoinCashAmountToDouble(amount);
      case CryptoCurrency.dash:
        return _dashAmountToDouble(amount);
      case CryptoCurrency.eth:
        return _ethereumAmountToDouble(amount);
      case CryptoCurrency.ltc:
        return _litecoinAmountToDouble(amount);
      case CryptoCurrency.xhv:
      case CryptoCurrency.xag:
      case CryptoCurrency.xau:
      case CryptoCurrency.xaud:
      case CryptoCurrency.xbtc:
      case CryptoCurrency.xcad:
      case CryptoCurrency.xchf:
      case CryptoCurrency.xcny:
      case CryptoCurrency.xeur:
      case CryptoCurrency.xgbp:
      case CryptoCurrency.xjpy:
      case CryptoCurrency.xnok:
      case CryptoCurrency.xnzd:
      case CryptoCurrency.xusd:
        return _moneroAmountToDouble(amount);
      default:
        return null;
    }
  }

  static int amountStringToInt(CryptoCurrency cryptoCurrency, String amount) {
    switch (cryptoCurrency) {
      case CryptoCurrency.xmr:
        return _moneroParseAmount(amount);
      case CryptoCurrency.wow:
        return _wowneroParseAmount(amount);
      case CryptoCurrency.xhv:
      case CryptoCurrency.xag:
      case CryptoCurrency.xau:
      case CryptoCurrency.xaud:
      case CryptoCurrency.xbtc:
      case CryptoCurrency.xcad:
      case CryptoCurrency.xchf:
      case CryptoCurrency.xcny:
      case CryptoCurrency.xeur:
      case CryptoCurrency.xgbp:
      case CryptoCurrency.xjpy:
      case CryptoCurrency.xnok:
      case CryptoCurrency.xnzd:
      case CryptoCurrency.xusd:
        return _moneroParseAmount(amount);
      default:
        return null;
    }
  }

  static String amountIntToString(CryptoCurrency cryptoCurrency, int amount) {
    switch (cryptoCurrency) {
      case CryptoCurrency.xmr:
        return _moneroAmountToString(amount);
      case CryptoCurrency.btc:
        return _bitcoinAmountToString(amount);
      case CryptoCurrency.wow:
        return _wowneroAmountToString(amount);
      case CryptoCurrency.xhv:
      case CryptoCurrency.xag:
      case CryptoCurrency.xau:
      case CryptoCurrency.xaud:
      case CryptoCurrency.xbtc:
      case CryptoCurrency.xcad:
      case CryptoCurrency.xchf:
      case CryptoCurrency.xcny:
      case CryptoCurrency.xeur:
      case CryptoCurrency.xgbp:
      case CryptoCurrency.xjpy:
      case CryptoCurrency.xnok:
      case CryptoCurrency.xnzd:
      case CryptoCurrency.xusd:
        return _moneroAmountToString(amount);
      default:
        return null;
    }
  }

  static double cryptoAmountToDouble({num amount, num divider}) =>
      amount / divider;

  static String _moneroAmountToString(int amount) => _moneroAmountFormat.format(
      cryptoAmountToDouble(amount: amount, divider: _moneroAmountDivider));

  static double _moneroAmountToDouble(int amount) =>
      cryptoAmountToDouble(amount: amount, divider: _moneroAmountDivider);

  static int _moneroParseAmount(String amount) =>
      _moneroAmountFormat.parse(amount).toInt();

  static String _wowneroAmountToString(int amount) => _wowneroAmountFormat.format(
      cryptoAmountToDouble(amount: amount, divider: _wowneroAmountDivider));

  static double _wowneroAmountToDouble(int amount) =>
      cryptoAmountToDouble(amount: amount, divider: _wowneroAmountDivider);

  static int _wowneroParseAmount(String amount) =>
      _wowneroAmountFormat.parse(amount).toInt();

  static String _bitcoinAmountToString(int amount) =>
      _bitcoinAmountFormat.format(
          cryptoAmountToDouble(amount: amount, divider: _bitcoinAmountDivider));

  static double _bitcoinAmountToDouble(int amount) =>
      cryptoAmountToDouble(amount: amount, divider: _bitcoinAmountDivider);

  static int _doubleToBitcoinAmount(double amount) =>
      (amount * _bitcoinAmountDivider).toInt();

  static double _bitcoinCashAmountToDouble(int amount) =>
      cryptoAmountToDouble(amount: amount, divider: _bitcoinCashAmountDivider);

  static double _dashAmountToDouble(int amount) =>
      cryptoAmountToDouble(amount: amount, divider: _dashAmountDivider);

  static double _ethereumAmountToDouble(num amount) =>
      cryptoAmountToDouble(amount: amount, divider: _ethereumAmountDivider);

  static double _litecoinAmountToDouble(int amount) =>
      cryptoAmountToDouble(amount: amount, divider: _litecoinAmountDivider);
}
