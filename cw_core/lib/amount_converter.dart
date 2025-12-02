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


  static String toBaseUnits(String amount, int decimals) {
    amount = amount.trim();
    if (amount.isEmpty) return '0';

    final neg = amount.startsWith('-');
    if (neg) amount = amount.substring(1);

    amount = amount.replaceAll(',', '');
    final parts = amount.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final frac  = parts.length > 1 ? parts[1] : '';

    final fracPadded = (frac + '0' * decimals).substring(0, decimals);

    final pow10 = BigInt.from(10).pow(decimals);
    final wholeBI = BigInt.parse(whole);
    final fracBI  = fracPadded.isEmpty ? BigInt.zero : BigInt.parse(fracPadded);

    final res = wholeBI * pow10 + fracBI;
    return neg ? '-${res.toString()}' : res.toString();
  }


  static String fromBaseUnits(String units, int decimals) {
    units = units.trim();
    if (units.isEmpty) return '0';

    final neg = units.startsWith('-');
    if (neg) units = units.substring(1);

    if (decimals == 0) return neg ? '-$units' : units;

    // pad if shorter than decimals
    if (units.length <= decimals) {
      final s = units.padLeft(decimals + 1, '0'); // ensures at least "0xxxx"
      final intPart = s.substring(0, s.length - decimals);
      var fracPart  = s.substring(s.length - decimals);
      fracPart = fracPart.replaceFirst(RegExp(r'0+$'), '');
      final out = fracPart.isEmpty ? intPart : '$intPart.$fracPart';
      return neg ? '-$out' : out;
    }

    final intPart = units.substring(0, units.length - decimals);
    var fracPart  = units.substring(units.length - decimals);
    fracPart = fracPart.replaceFirst(RegExp(r'0+$'), '');
    final out = fracPart.isEmpty ? intPart : '$intPart.$fracPart';
    return neg ? '-$out' : out;
  }
}
