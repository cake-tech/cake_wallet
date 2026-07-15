import 'package:cw_core/parse_fixed.dart';

String formatFixed(BigInt value, int? decimals, {int? fractionalDigits, bool trimZeros = true}) {
  decimals ??= 0;
  fractionalDigits ??= decimals;

  final multiplier = multiplierOf(decimals);
  var negative = value.isNegative;
  if (negative) value = -value;

  var fraction = (value % multiplier).toString().padLeft(decimals, "0");

  if (fractionalDigits < 0) fractionalDigits = 0;
  if (fractionalDigits > decimals) fractionalDigits = decimals;
  fraction = fraction.substring(0, fractionalDigits);

  if (trimZeros) {
    fraction = removeTrailing("0", fraction);
  }

  final whole = value ~/ multiplier;

  final valString = fraction.isEmpty ? "$whole" : "$whole.$fraction";

  if (negative) return "-$valString";

  return valString;
}

String removeTrailing(String pattern, String from) {
  if (pattern.isEmpty) return from;
  var i = from.length;
  while (i > 0 && from.startsWith(pattern, i - pattern.length)) {
    i -= pattern.length;
  }
  return from.substring(0, i);
}
