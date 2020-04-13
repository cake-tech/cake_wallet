import 'package:intl/intl.dart';

final amountFormat = NumberFormat()
  ..maximumFractionDigits = 3
  ..minimumFractionDigits = 1;

double limitsFormat(double limit) => double.parse(amountFormat.format(limit));