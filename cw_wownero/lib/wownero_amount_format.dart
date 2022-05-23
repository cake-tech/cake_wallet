import 'package:intl/intl.dart';
import 'package:cw_core/crypto_amount_format.dart';

const wowneroAmountLength = 11;
const wowneroAmountDivider = 100000000000;
final wowneroAmountFormat = NumberFormat()
  ..maximumFractionDigits = wowneroAmountLength
  ..minimumFractionDigits = 1;

String wowneroAmountToString({int amount}) => wowneroAmountFormat
    .format(cryptoAmountToDouble(amount: amount, divider: wowneroAmountDivider))
    .replaceAll(',', '');

double wowneroAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: wowneroAmountDivider);

int wowneroParseAmount({String amount}) =>
    (double.parse(amount) * wowneroAmountDivider).toInt();
