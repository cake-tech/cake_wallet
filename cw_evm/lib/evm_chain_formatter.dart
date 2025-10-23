import 'dart:math';

class EVMChainFormatter {
  static int _divider = 0;

  static int parseEVMChainAmount(String amount) {
    try {
      final decimalLength = _getDividerForInput(amount);
      _divider = decimalLength;
      return (double.parse(amount) * pow(10, decimalLength)).round();
    } catch (_) {
      return 0;
    }
  }

  static double parseEVMChainAmountToDouble(int amount) {
    try {
      return amount / pow(10, _divider);
    } catch (_) {
      return 0;
    }
  }

  static String truncateDecimals(String amount, int decimals) {
    final parts = amount.split(".");

    if (parts.length == 2) {
      parts[1] = parts[1].substring(0, parts[1].length > decimals ? decimals : parts[1].length);
    }

    return parts.join(".");
  }

  static int _getDividerForInput(String amount) {
    final result = amount.split('.');
    if (result.length > 1) {
      final decimalLength = result[1].length;
      return decimalLength;
    } else {
      return 0;
    }
  }
}
