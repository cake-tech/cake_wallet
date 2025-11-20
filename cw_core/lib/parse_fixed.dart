BigInt parseFixed(String value, int decimals) {
  final multiplier = getMultiplier(decimals);

  final negative = value.startsWith("-");
  if (negative) value = value.substring(1);

  if (value == ".") throw Exception("missing value, value, $value");

  if (value.startsWith(".")) value = "0$value";

  final comps = value.split(".");
  if (comps.length > 2) {
    throw Exception("too many decimal points, value, $value");
  }

  var whole = comps.isNotEmpty ? comps[0] : "0";
  var fraction = (comps.length == 2 ? comps[1] : "0").padRight(decimals, "0");

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
