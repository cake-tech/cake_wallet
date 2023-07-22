import 'dart:math';

import 'package:intl/intl.dart';

const ethereumAmountLength = 12;
const ethereumAmountDivider = 1000000000000;
final ethereumAmountFormat = NumberFormat()
  ..maximumFractionDigits = ethereumAmountLength
  ..minimumFractionDigits = 1;

class EthereumFormatter {
  static int parseEthereumAmount(String amount) {
    try {
      return (double.parse(amount) * ethereumAmountDivider).round();
    } catch (_) {
      return 0;
    }
  }

  static int parseEthereumBigIntAmount(BigInt amount) {
    try {
      double result = amount / BigInt.from(pow(10, 18 - ethereumAmountLength));
      return result.toInt();
    } catch (_) {
      return 0;
    }
  }
}
