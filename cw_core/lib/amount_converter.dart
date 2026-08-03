class AmountConverter {
  static String toBaseUnits(String amount, int decimals) {
    amount = amount.trim();
    if (amount.isEmpty) return '0';

    final neg = amount.startsWith('-');
    if (neg) amount = amount.substring(1);

    amount = amount.replaceAll(',', '');
    final parts = amount.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts.length > 1 ? parts[1] : '';

    final fracPadded = (frac + '0' * decimals).substring(0, decimals);

    final pow10 = BigInt.from(10).pow(decimals);
    final wholeBI = BigInt.parse(whole);
    final fracBI = fracPadded.isEmpty ? BigInt.zero : BigInt.parse(fracPadded);

    final res = wholeBI * pow10 + fracBI;
    return neg ? '-${res.toString()}' : res.toString();
  }

  static String fromBaseUnits(String units, int decimals) {
    units = units.trim();
    if (units.isEmpty) return '0';

    final neg = units.startsWith('-');
    if (neg) units = units.substring(1);

    if (decimals == 0) return neg ? '-$units' : units;

    // pad if shorter than decimals
    if (units.length <= decimals) {
      final s = units.padLeft(decimals + 1, '0'); // ensures at least "0xxxx"
      final intPart = s.substring(0, s.length - decimals);
      var fracPart = s.substring(s.length - decimals);
      fracPart = fracPart.replaceFirst(RegExp(r'0+$'), '');
      final out = fracPart.isEmpty ? intPart : '$intPart.$fracPart';
      return neg ? '-$out' : out;
    }

    final intPart = units.substring(0, units.length - decimals);
    var fracPart = units.substring(units.length - decimals);
    fracPart = fracPart.replaceFirst(RegExp(r'0+$'), '');
    final out = fracPart.isEmpty ? intPart : '$intPart.$fracPart';
    return neg ? '-$out' : out;
  }
}
