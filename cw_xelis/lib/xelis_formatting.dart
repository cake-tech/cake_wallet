import 'dart:math';

class XelisFormatter {
  static int parseXelisAmount(String amount) {
    try {
      return (double.parse(amount) * pow(10, 8)).round();
    } catch (_) {
      return 0;
    }
  }

  static double parseXelisAmountToDouble(int amount) {
    try {
      return amount / pow(10, 8);
    } catch (_) {
      return 0;
    }
  }

  static int parseAmount(String amount, int decimals) {
    try {
      return (double.parse(amount) * pow(10, decimals)).round();
    } catch (_) {
      return 0;
    }
  }

  static double parseAmountToDouble(int amount, int decimals) {
    try {
      return amount / pow(10, decimals);
    } catch (_) {
      return 0;
    }
  }

  static String formatAmountWithSymbol(
    int rawAmount, {
    required int decimals,
    String? symbol,
  }) {
    final formatted = rawAmount / pow(10, decimals);
    // final symbol = assetId == null || assetId == xelisAsset ? 'XEL' : assetId;
    final sym = symbol ?? 'XEL';
    return '$formatted $sym';
  }

  static String formatAmount(
    int rawAmount, {
    required int decimals,
  }) {
    final formatted = rawAmount / pow(10, decimals);
    return '$formatted';
  }
}
