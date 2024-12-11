import 'package:intl/intl.dart';
import 'package:cw_core/crypto_amount_format.dart';

const salviumAmountLength = 8;
const salviumAmountDivider = 100000000;
final salviumAmountFormat = NumberFormat()
  ..maximumFractionDigits = salviumAmountLength
  ..minimumFractionDigits = 1;

String salviumAmountToString({required int amount}) => salviumAmountFormat
    .format(cryptoAmountToDouble(amount: amount, divider: salviumAmountDivider))
    .replaceAll(',', '');

double salviumAmountToDouble({required int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: salviumAmountDivider);

int salviumParseAmount({required String amount}) =>
    (double.parse(amount) * salviumAmountDivider).round();
