import 'dart:math';

class EVMChainFormatter {
  static const int evmDecimals = 18;

  static int parseEVMChainAmount(String amount) {
    try {
      return (double.parse(amount) * pow(10, evmDecimals)).round();
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
}
