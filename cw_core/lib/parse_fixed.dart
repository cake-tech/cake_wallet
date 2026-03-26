/// Parses the string [value] as a fixed-point decimal literal and returns its
/// [BigInt] value.
///
/// The number of fractional digits is determined by [decimals].
///
/// Returns `null` if the input [value] is not a valid fixed-point literal
/// (e.g., non-numeric characters, too many fractional digits).
///
/// Like [parseFixed], except that this function returns `null` for invalid inputs
/// instead of throwing.
BigInt? tryParseFixed(String value, int decimals) {
  try {
    return parseFixed(value, decimals);
  } on FormatException catch (_) {
    return null;
  }
}

/// Parses the string [value] as a fixed-point decimal literal and returns its
/// [BigInt] value.
///
/// The number of fractional digits is determined by [decimals].
///
/// Throws a [FormatException] if the input [value] is not a valid fixed-point literal
/// (e.g., non-numeric characters, too many fractional digits).
///
/// Rather than throwing and immediately catching the [FormatException],
/// instead use [tryParseFixed] to handle a potential parsing error.
BigInt parseFixed(String value, int decimals) {
  final multiplier = getMultiplier(decimals);

  final negative = value.startsWith("-");
  if (negative) value = value.substring(1);

  if (value == ".") throw FormatException("missing value, value, $value");

  if (value.startsWith(".")) value = "0$value";

  final comps = value.split(".");
  if (comps.length > 2) {
    throw FormatException("too many decimal points, value, $value");
  }

  var whole = comps.isNotEmpty ? comps[0] : "0";
  var fraction = comps.length == 2 ? comps[1] : "";



  var wholeValue = BigInt.parse(whole);
  final multiplierValue = BigInt.parse(multiplier);
  BigInt fractionValue;

  if (fraction.isEmpty) {
    fractionValue = BigInt.zero;
  } else if (fraction.length <= decimals) {
    fractionValue = BigInt.parse(fraction.padRight(decimals, '0'));
  } else {
    final excess = fraction.length - decimals;
    final divisor = BigInt.parse('1'.padRight(excess + 1, '0'));
    final fracNum = BigInt.parse(fraction);
    final half = divisor ~/ BigInt.from(2);
    fractionValue = (fracNum + half) ~/ divisor;
    while (fractionValue >= multiplierValue) {
      wholeValue += BigInt.one;
      fractionValue -= multiplierValue;
    }
  }

  var wei = (wholeValue * multiplierValue) + fractionValue;

  if (negative) wei *= BigInt.from(-1);

  return wei;
}

// Returns a string "1" followed by decimal "0"s
String getMultiplier(int decimals) => "1".padRight(decimals + 1, "0");
