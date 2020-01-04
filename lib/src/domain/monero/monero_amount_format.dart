import 'package:intl/intl.dart';

const moneroAmountLength = 12;
const moneroAmountDivider = 1000000000000;
final moneroAmountFormat = NumberFormat()
  ..maximumFractionDigits = moneroAmountLength
  ..minimumFractionDigits = 1;

String moneroAmountToString({int amount}) =>
    moneroAmountFormat.format(amount / moneroAmountDivider);

double moneroAmountToDouble({int amount}) => amount / moneroAmountDivider;
