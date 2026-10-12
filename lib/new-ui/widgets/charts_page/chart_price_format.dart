import "dart:math";

import "package:cw_core/amount/money.dart";
import "package:cw_core/format_fixed.dart";

/// Fraction digits to display a chart price with: 2 by default, more for
/// non-zero values below 1 so that two significant digits are shown
/// (e.g. 0.054, 0.000012), capped at 12.
int chartPriceDecimals(double price) {
  final abs = price.abs();
  if (!(abs > 0 && abs < 1)) return 2;

  final leadingZeros = abs.toStringAsFixed(20).substring(2).indexOf(RegExp("[1-9]"));
  if (leadingZeros < 0) return 2;

  return min(leadingZeros + 2, 12);
}

extension ChartPriceFormat on Money {
  /// Same as `toStringWithPrecision(fractionalDigits: 2)`, except that low values
  /// get enough decimals to show two significant digits.
  String toChartPriceString() {
    final decimals = chartPriceDecimals(double.parse(toString()));
    return decimals == 2
        ? toStringWithPrecision(fractionalDigits: 2)
        : formatFixed(amount, this.decimals, fractionalDigits: decimals);
  }
}
