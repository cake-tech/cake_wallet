import 'package:intl/intl.dart';
import 'package:cw_core/crypto_amount_format.dart';

const moneroAmountLength = 12;
const moneroAmountDivider = 1000000000000;
final moneroAmountFormat = NumberFormat()
  ..maximumFractionDigits = moneroAmountLength
  ..minimumFractionDigits = 1;

String moneroAmountToString({int amount}) => moneroAmountFormat
    .format(cryptoAmountToDouble(amount: amount, divider: moneroAmountDivider))
    .replaceAll(',', '');

double moneroAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: moneroAmountDivider);

int moneroParseAmount({String amount}) =>
    (double.parse(amount) * moneroAmountDivider).toInt();
