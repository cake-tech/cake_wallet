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

  /// Parse EVM chain amount to BigInt to avoid integer overflow for large amounts
  static BigInt parseEVMChainAmountToBigInt(String amount) {
    try {
      final parts = amount.replaceAll(',', '.').split('.');
      final whole = parts[0].isEmpty ? '0' : parts[0];
      final fraction = parts.length > 1 ? parts[1] : '';

      final fractionPadded = fraction
          .padRight(evmDecimals, '0')
          .substring(0, evmDecimals > fraction.length ? evmDecimals : fraction.length);

      final wholeBigInt = BigInt.parse(whole);
      final fractionBigInt = BigInt.parse(fractionPadded);
      final multiplier = BigInt.from(10).pow(evmDecimals);

      return (wholeBigInt * multiplier) + fractionBigInt;
    } catch (_) {
      return BigInt.zero;
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
