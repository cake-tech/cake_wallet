import 'package:intl/intl.dart';
import 'package:cw_core/crypto_amount_format.dart';

const minotariAmountLength = 6;
const minotariAmountDivider = 1000000;
final minotariAmountFormat = NumberFormat()
  ..maximumFractionDigits = minotariAmountLength
  ..minimumFractionDigits = 1;

String minotariAmountToString({required int amount}) => minotariAmountFormat
    .format(cryptoAmountToDouble(amount: amount, divider: minotariAmountDivider));

double minotariAmountToDouble({required int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: minotariAmountDivider);

int minotariParseAmount({required String amount}) =>
    (double.parse(amount) * minotariAmountDivider).round();

