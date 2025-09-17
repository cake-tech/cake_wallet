import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:intl/intl.dart';
import 'package:cw_core/crypto_currency.dart';

class AmountConverter {
  static const _moneroAmountLength = 12;
  static const _moneroAmountDivider = 1000000000000;
  static const _wowneroAmountLength = 11;
  static const _wowneroAmountDivider = 100000000000;
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

  static String amountIntToString(CryptoCurrency cryptoCurrency, int amount) {
    switch (cryptoCurrency) {
      case CryptoCurrency.xmr:
        return _moneroAmountToString(amount);
      case CryptoCurrency.wow:
        return _wowneroAmountToString(amount);
      case CryptoCurrency.btc:
      case CryptoCurrency.bch:
      case CryptoCurrency.ltc:
      case CryptoCurrency.dcr:
      case CryptoCurrency.doge:
        return _bitcoinAmountToString(amount);
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
      case CryptoCurrency.zano:
        return _moneroAmountToStringUsingDecimals(amount);
      default:
        return '';
    }
  }

  static double cryptoAmountToDouble({required num amount, required num divider}) =>
      amount / divider;

  static String _moneroAmountToString(int amount) => _moneroAmountFormat
      .format(cryptoAmountToDouble(amount: amount, divider: _moneroAmountDivider));

  static String _bitcoinAmountToString(int amount) => _bitcoinAmountFormat
      .format(cryptoAmountToDouble(amount: amount, divider: _bitcoinAmountDivider));

  static String _wowneroAmountToString(int amount) => _wowneroAmountFormat
      .format(cryptoAmountToDouble(amount: amount, divider: _wowneroAmountDivider));

  static Decimal cryptoAmountToDecimal({required int amount, required int divider}) =>
    (Decimal.fromInt(amount) / Decimal.fromInt(divider)).toDecimal();
  
  static String _moneroAmountToStringUsingDecimals(int amount) => _moneroAmountFormat.format(
    DecimalIntl(cryptoAmountToDecimal(amount: amount, divider: _moneroAmountDivider)));

  static String toMinimalUnits(CryptoCurrency cryptoCurrency, double amount) {
    final decimals = _decimalsForCurrency(cryptoCurrency);
    final d = Decimal.parse(amount.toString());
    final factor = Decimal.parse('1' + List.filled(decimals, '0').join());
    final scaled = d * factor;
    final s = scaled.toString();
    final dot = s.indexOf('.');
    return dot == -1 ? s : s.substring(0, dot);
  }

  static int _decimalsForCurrency(CryptoCurrency cur) {
    switch (cur) {
      case CryptoCurrency.btc:
      case CryptoCurrency.bch:
      case CryptoCurrency.ltc:
      case CryptoCurrency.dcr:
      case CryptoCurrency.doge:
      case CryptoCurrency.dash:
      case CryptoCurrency.zec:
        return 8;
      case CryptoCurrency.xmr:
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
        return 12;
      case CryptoCurrency.wow:
        return 11;
      case CryptoCurrency.zano:
        return 12;
      case CryptoCurrency.eth:
      case CryptoCurrency.ape:
        return 18;
      case CryptoCurrency.trx:
        return 6;
      case CryptoCurrency.xrp:
        return 6;
      case CryptoCurrency.xlm:
        return 7;
      case CryptoCurrency.ada:
      case CryptoCurrency.usdterc20:
        return 6;
      case CryptoCurrency.sol:
        return 9;
      default:
        return 8;
    }
  }
}
