import 'dart:math';

class XelisFormatter {
  static int _divider = 0;

  static int parseXelisAmount(String amount) {
    try {
      final decimalLength = _getDividerForInput(amount);
      _divider = decimalLength;
      return (double.parse(amount) * pow(10, decimalLength)).round();
    } catch (_) {
      return 0;
    }
  }

  static double parseXelisAmountToDouble(int amount) {
    try {
      return amount / pow(10, _divider);
    } catch (_) {
      return 0;
    }
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

String formatXelisAmountWithSymbol(
  int rawAmount, {
  required int decimals,
  String? symbol,
}) {
  final formatted = rawAmount / pow(10, decimals);
  // final symbol = assetId == null || assetId == xelisAsset ? 'XEL' : assetId;
  final sym = symbol ?? 'XEL';
  return '$formatted $sym';
}

String formatXelisAmount(
  int rawAmount, {
  required int decimals,
}) {
  final formatted = rawAmount / pow(10, decimals);
  return '$formatted';
}
