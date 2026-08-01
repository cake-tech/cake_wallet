/// Parses the string [value] as a fixed-point decimal literal and returns its
/// [BigInt] value.
///
/// The number of fractional digits is determined by [decimals].
///
/// Fractional digits beyond [decimals] are truncated, see [parseFixed].
///
/// Returns `null` if the input [value] is not a valid fixed-point literal
/// (e.g., non-numeric characters, more than one decimal point).
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
/// Excess precision is **truncated, never rounded**: any fractional digit past
/// [decimals] is dropped, so `parseFixed("1.9999999", 6)` is `1999999` and not
/// `2000000`. Truncation is applied to the magnitude and is therefore always
/// toward zero, so `parseFixed("-1.9999999", 6)` is `-1999999`. A value whose
/// entire fractional part sits below the smallest representable unit (e.g.
/// `parseFixed("0.0000001", 6)`) is genuinely `0` after truncation.
///
/// Throws a [FormatException] if the input [value] is not a valid fixed-point literal
/// (e.g., non-numeric characters, more than one decimal point).
///
/// Rather than throwing and immediately catching the [FormatException],
/// instead use [tryParseFixed] to handle a potential parsing error.
BigInt parseFixed(String value, int decimals) {
  /// handle weird cases where users enter spaces and currency after the amount
  /// This should be handled from UI field to prevent non numerical values
  /// but will be in the refactoring
  if (value.contains(" ")) {
    value = value.split(" ").first;
  }

  final negative = value.startsWith("-");
  if (negative) value = value.substring(1);

  if (value == ".") throw FormatException("missing value, value, $value");

  if (value.startsWith(".")) value = "0$value";

  final comps = value.split(".");
  if (comps.length > 2) {
    throw FormatException("too many decimal points, value, $value");
  }

  var whole = comps.isNotEmpty ? comps[0] : "0";
  var fraction = (comps.length == 2 ? comps[1] : "0").padRight(decimals, "0");

  // Truncate, do not round: digits beyond the currency's precision are simply
  // dropped. Because `negative` has already been stripped off, this operates on
  // the magnitude and so always truncates toward zero.
  if (fraction.length > decimals) {
    fraction = fraction.substring(0, decimals);
  }

  final wholeValue = BigInt.parse(whole);
  // `fraction` is empty when [decimals] is 0, in which case there is no
  // fractional component to add.
  final fractionValue = fraction.isEmpty ? BigInt.zero : BigInt.parse(fraction);
  final multiplierValue = multiplierOf(decimals);

  var wei = (wholeValue * multiplierValue) + fractionValue;

  if (negative) wei *= BigInt.from(-1);

  return wei;
}

// Returns a string "1" followed by decimal "0"s
String getMultiplier(int decimals) => "1".padRight(decimals + 1, "0");

final _multipliers = <int, BigInt>{};

// this is more direct and faster than having it as string then parsing everytime to get the number
BigInt multiplierOf(int decimals) => _multipliers[decimals] ??= BigInt.from(10).pow(decimals);
