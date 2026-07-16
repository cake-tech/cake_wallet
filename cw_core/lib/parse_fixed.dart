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

  if (fraction.length > multiplier.length - 1) {
    throw FormatException(
        "fractional component(${fraction.length}) exceeds decimals(${decimals}), underflow, parseFixed");
  }

  final wholeValue = BigInt.parse(whole);
  final fractionValue = BigInt.parse(fraction);
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
