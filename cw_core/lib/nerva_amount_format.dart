import 'package:intl/intl.dart';
import 'package:cw_core/crypto_amount_format.dart';

const nervaAmountLength = 12;
const nervaAmountDivider = 1000000000000;
final nervaAmountFormat = NumberFormat()
  ..maximumFractionDigits = nervaAmountLength
  ..minimumFractionDigits = 1;

String nervaAmountToString({required int amount}) => nervaAmountFormat
    .format(cryptoAmountToDouble(amount: amount, divider: nervaAmountDivider))
    .replaceAll(',', '');

double nervaAmountToDouble({required int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: nervaAmountDivider);

int nervaParseAmount({required String amount}) =>
    (double.parse(amount) * nervaAmountDivider).round();
