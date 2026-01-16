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
  /// [decimals] defaults to 18 for native ETH/POL, but should be set to token decimals for ERC20 tokens
  static BigInt parseEVMChainAmountToBigInt(String amount, {int decimals = evmDecimals}) {
    try {
      String cleanAmount = amount.replaceAll(',', '.');

      bool isNegative = cleanAmount.startsWith('-');
      if (isNegative) {
        cleanAmount = cleanAmount.substring(1);
      }

      final parts = cleanAmount.split('.');
      String whole = parts[0].isEmpty ? '0' : parts[0];
      String fraction = parts.length > 1 ? parts[1] : '';

      // 3. Strict Truncation Logic
      // If fraction is longer than decimals, strictly cut it off.
      // If shorter, pad it with zeros.
      if (fraction.length > decimals) {
        fraction = fraction.substring(0, decimals);
      } else {
        fraction = fraction.padRight(decimals, '0');
      }

      final wholeBigInt = BigInt.parse(whole);
      final fractionBigInt = BigInt.parse(fraction);
      final multiplier = BigInt.from(10).pow(decimals);

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
