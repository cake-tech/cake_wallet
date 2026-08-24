import "dart:math";

import "package:cw_core/amount/utils.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/format_fixed.dart";
import "package:cw_core/parse_fixed.dart";

export "money_local.dart";

class Money implements Comparable<Money> {
  const Money(this.amount, this.currency, [int? overrideDecimals])
      : _overrideDecimals = overrideDecimals;

  factory Money.zero(Currency currency) => Money(BigInt.zero, currency);

  factory Money.fromInt(int amount, Currency currency) => Money(BigInt.from(amount), currency);

  /// Parse the [source] and turn it into [Money] trimming trailing 0s
  ///
  /// Throws a [FormatException] if the [source] is not a valid decimal or
  /// not in canonical representation or if it is a decimal when [isBaseUnit]
  factory Money.parse(
    String source,
    Currency currency, {
    bool isBaseUnit = false,
    bool strictParsing = true,
  }) {
    if (!isBaseUnit) {
      source = trimTrailingFractionZeros(source);
    }
    final decimals = strictParsing ? currency.decimals : _getActualDecimals(source, currency);
    final amount = isBaseUnit ? BigInt.parse(source) : parseFixed(source, decimals);

    return Money(amount, currency, decimals);
  }

  /// Parse the [source] and turn it into [Money] if possible trimming trailing 0s
  ///
  /// As [parse] except that this method returns `null` if the input is not
  /// valid or if it is a decimal when [isBaseUnit]
  static Money? tryParse(
    String source,
    Currency currency, {
    bool isBaseUnit = false,
    bool strictParsing = true,
  }) {
    try {
      if (!isBaseUnit) {
        source = trimTrailingFractionZeros(source);
      }
      final decimals = strictParsing ? currency.decimals : _getActualDecimals(source, currency);
      final amount = isBaseUnit ? BigInt.tryParse(source) : tryParseFixed(source, decimals);

      return amount != null ? Money(amount, currency, decimals) : null;
    } catch (_) {
      return null;
    }
  }

  final BigInt amount;
  final Currency currency;

  final int? _overrideDecimals;

  /// Returns the amount of decimals of [currency]
  int get decimals => _overrideDecimals ?? currency.decimals;

  /// Returns the sign of this [BigInt] amount.
  /// Returns 0 for zero, -1 for values less than zero and +1 for values
  /// greater than zero.
  int get sign => amount.sign;

  /// Returns `true` when amount of this money is zero.
  bool get isZero => amount == BigInt.zero;

  /// Returns `true` when amount of this money is negative.
  bool get isNegative => amount.isNegative;

  /// Compares this to [other].
  ///
  /// [other] has to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);

    final aligned = _align(other);
    return aligned.a.compareTo(aligned.b);
  }

  /// Returns `true` if [other] is the same amount of money in
  /// the same currency.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Money || other.currency != currency) {
      return false;
    }

    final aligned = _align(other);
    return aligned.a == aligned.b;
  }

  /// Returns `true` when this money is less than [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator <(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    final aligned = _align(other);
    return aligned.a < aligned.b;
  }

  /// Returns `true` when this money is less than or equal to [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator <=(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    final aligned = _align(other);
    return aligned.a <= aligned.b;
  }

  /// Returns `true` when this money is greater than [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator >(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    final aligned = _align(other);
    return aligned.a > aligned.b;
  }

  /// Returns `true` when this money is greater than or equal to [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator >=(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    final aligned = _align(other);
    return aligned.a >= aligned.b;
  }

  /// Adds the amount of [other] to this amount.
  ///
  /// Both operands must be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  Money operator +(Money other) {
    _assertSameCurrency(other);

    final aligned = _align(other);
    return copyWith(amount: aligned.a + aligned.b, decimals: aligned.decimals);
  }

  /// unary minus operator.
  Money operator -() => copyWith(amount: -amount);

  /// Subtracts the amount of [other] from this amount.
  ///
  /// Both operands must be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  Money operator -(Money other) {
    _assertSameCurrency(other);

    final aligned = _align(other);
    return copyWith(amount: aligned.a - aligned.b, decimals: aligned.decimals);
  }

  /// Returns [Money] multiplied by [other].
  ///
  /// The result is again [Money].
  Money operator *(BigInt other) => copyWith(amount: amount * other);

  /// Returns [Money] divided by [other].
  ///
  /// The result is again [Money].
  Money operator /(BigInt other) {
    if (other == BigInt.zero) {
      throw Exception("Division by zero.");
    }

    final neg = (amount.isNegative) ^ (other.isNegative);
    final A = amount.abs();
    final B = other.abs();

    final q = A ~/ B;
    final r = A % B;

    // Compare 2*r with B to detect half/up/down
    final twiceR = r << 1;
    final mag = (twiceR >= B) ? q + BigInt.one : q;

    return copyWith(amount: neg ? -mag : mag);
  }

  /// Creates a copy of this [Money] object with optional new values
  /// for [amount], [currency].
  ///
  /// If just [currency] is provided and the decimals missmatch
  /// the amount will be transformed to keep its canonical representation
  Money copyWith({BigInt? amount, Currency? currency, int? decimals}) {
    if (currency != null && amount == null && decimals == null &&
        currency.decimals != this.decimals) {
      return Money(
        _transformAmount(this.amount, this.decimals, currency.decimals),
        currency,
        currency.decimals,
      );
    }

    return Money(amount ?? this.amount, currency ?? this.currency, decimals ?? this.decimals);
  }

  void _assertSameCurrency(Money other, [String? message]) {
    if (currency != other.currency) {
      throw ArgumentError(message ?? "Cannot operate with money values in different currencies.");
    }
  }

  static BigInt _transformAmount(BigInt source, int sourceDecimals, int targetDecimals) {
    final diff = targetDecimals - sourceDecimals;

    return diff == 0
        ? source
        : diff > 0
            ? source * BigInt.from(10).pow(diff)
            : source ~/ BigInt.from(10).pow(-diff);
  }

  ({BigInt a, BigInt b, int decimals}) _align(Money other) {
    final decimals = max(this.decimals, other.decimals);
    return (
      a: _transformAmount(amount, this.decimals, decimals),
      b: _transformAmount(other.amount, other.decimals, decimals),
      decimals: decimals,
    );
  }

  static int _getActualDecimals(String value, Currency currency) {
    final comps = value.split(".");
    if (comps.length > 2) {
      throw FormatException("Money._getActualDecimals: too many decimal points, value, $value");
    }

    return max(comps.length == 2 ? comps[1].length : 0, currency.decimals);
  }

  @override
  int get hashCode {
    final value = formatFixed(amount, this.decimals, trimZeros: true);
    final decimals = _getActualDecimals(value, currency);

    return Object.hash(value, decimals, currency);
  }

  @override
  String toString() => formatFixed(amount, decimals);

  String toStringWithSymbol({
    int? fractionalDigits,
    bool trimZeros = true,
    bool useBaseUnit = false,
    bool withSymbolPrefix = false,
  }) {
    final amount = toStringWithPrecision(
      fractionalDigits: fractionalDigits,
      trimZeros: trimZeros,
      useBaseUnit: useBaseUnit,
    );
    final symbol = getSymbol(useBaseUnit: useBaseUnit);

    return withSymbolPrefix ? "$symbol $amount" : "$amount $symbol";
  }

  String toStringWithPrecision({
    int? fractionalDigits,
    bool trimZeros = true,
    bool useBaseUnit = false,
  }) =>
      formatFixed(
        decimals != currency.decimals
            ? _transformAmount(amount, decimals, currency.decimals)
            : amount,
        useBaseUnit ? 0 : currency.decimals,
        fractionalDigits: fractionalDigits,
        trimZeros: trimZeros,
      );

  // To Override the symbol with the ticker of the base unit
  String getSymbol({required bool useBaseUnit}) {
    if (useBaseUnit && [CryptoCurrency.btc, CryptoCurrency.btcln].contains(currency)) {
      return "sats";
    }
    return currency.symbol;
  }
}
