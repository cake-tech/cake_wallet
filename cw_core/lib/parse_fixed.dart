BigInt parseFixed(String value, int? decimals) {
  decimals ??= 0;
  final multiplier = getMultiplier(decimals);

// Is it negative?
  final negative = (value.substring(0, 1) == "-");
  if (negative) value = value.substring(1);

  if (value == ".") throw Exception("missing value, value, $value");

// Split it into a whole and fractional part
  final comps = value.split(".");
  if (comps.length > 2) {
    throw Exception("too many decimal points, value, $value");
  }

  var whole = comps.isNotEmpty ? comps[0] : "0";
  var fraction = (comps.length == 2 ? comps[1] : "0").padRight(decimals, "0");

  // Check the fraction doesn't exceed our decimals size
  if (fraction.length > multiplier.length - 1) {
    throw Exception(
        "fractional component exceeds decimals, underflow, parseFixed");
  }

  final wholeValue = BigInt.parse(whole);
  final fractionValue = BigInt.parse(fraction);
  final multiplierValue = BigInt.parse(multiplier);

  var wei = (wholeValue * multiplierValue) + fractionValue;

  if (negative) wei *= BigInt.from(-1);

  return wei;
}

// Returns a string "1" followed by decimal "0"s
String getMultiplier(int decimals) => "1".padRight(decimals + 1, "0");
