import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:intl/intl.dart';

class ZanoFormatter {
  static const defaultDecimalPoint = 12;

  static final numberFormat = NumberFormat()
    ..maximumFractionDigits = defaultDecimalPoint
    ..minimumFractionDigits = 1;

  static Decimal _intDivision({required int amount, required BigInt divider}) => (Decimal.fromInt(amount) / Decimal.fromBigInt(divider)).toDecimal();
  static Decimal _bigIntDivision({required BigInt amount, required BigInt divider}) =>
      (Decimal.fromBigInt(amount) / Decimal.fromBigInt(divider)).toDecimal();

  static String intAmountToString(int amount, [int decimalPoint = defaultDecimalPoint]) => numberFormat.format(
        DecimalIntl(
          _intDivision(
            amount: amount,
            divider: BigInt.from(pow(10, decimalPoint)),
          ),
        ),
      ).replaceAll(',', '');
  static String bigIntAmountToString(BigInt amount, [int decimalPoint = defaultDecimalPoint]) => numberFormat.format(
        DecimalIntl(
          _bigIntDivision(
            amount: amount,
            divider: BigInt.from(pow(10, decimalPoint)),
          ),
        ),
      ).replaceAll(',', '');
}
