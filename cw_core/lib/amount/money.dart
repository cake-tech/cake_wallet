import "package:cw_core/crypto_amount_format.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/format_fixed.dart";
import "package:cw_core/parse_fixed.dart";

export "money_local.dart";

class Money implements Comparable<Money> {
  const Money(this.amount, this.currency);

  factory Money.zero(Currency currency) => Money(BigInt.zero, currency);

  factory Money.fromInt(int amount, Currency currency) => Money(BigInt.from(amount), currency);

  /// Parse the [source] and turn it into [Money]
  ///
  /// Throws a [FormatException] if the [source] is not a valid decimal or
  /// not in canonical representation or if it is a decimal when [isBaseUnit]
  factory Money.parse(source, Currency currency, {bool isBaseUnit = false}) {
    final amount = isBaseUnit
        ? BigInt.parse(source.toString())
        : parseFixed(source.toString(), currency.decimals);

    return Money(amount, currency);
  }

  /// Parse the [source] and turn it into [Money] if possible
  ///
  /// As [parse] except that this method returns `null` if the input is not
  /// valid or if it is a decimal when [isBaseUnit]
  static Money? tryParse(source, Currency currency, {bool isBaseUnit = false}) {
    final amount = isBaseUnit
        ? BigInt.tryParse(source.toString())
        : tryParseFixed(source.toString(), currency.decimals);

    return amount != null ? Money(amount, currency) : null;
  }

  final BigInt amount;
  final Currency currency;

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

    return amount.compareTo(other.amount);
  }

  /// Returns `true` if [other] is the same amount of money in
  /// the same currency.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Money && other.currency == currency && other.amount == amount);

  /// Returns `true` when this money is less than [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator <(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    return amount < other.amount;
  }

  /// Returns `true` when this money is less than or equal to [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator <=(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    return amount <= other.amount;
  }

  /// Returns `true` when this money is greater than [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator >(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    return amount > other.amount;
  }

  /// Returns `true` when this money is greater than or equal to [other].
  ///
  /// Both operands have to be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  bool operator >=(Money other) {
    _assertSameCurrency(other, "Cannot compare money in different currencies.");

    return amount >= other.amount;
  }

  /// Adds the amount of [other] to this amount.
  ///
  /// Both operands must be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  Money operator +(Money other) {
    _assertSameCurrency(other);

    return _withAmount(amount + other.amount);
  }

  /// unary minus operator.
  Money operator -() => _withAmount(-amount);

  /// Subtracts the amount of [other] from this amount.
  ///
  /// Both operands must be in same currency, [ArgumentError] will be thrown
  /// otherwise.
  Money operator -(Money other) {
    _assertSameCurrency(other);

    return _withAmount(amount - other.amount);
  }

  /// Returns [Money] multiplied by [other].
  ///
  /// The result is again [Money].
  Money operator *(BigInt other) => _withAmount(amount * other);

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

    return _withAmount(neg ? -mag : mag);
  }

  /// Creates a copy of this [Money] object with optional new values
  /// for [amount], [currency].
  ///
  /// If just [currency] is provided and the decimals missmatch
  /// the amount will be transformed to keep its canonical representation
  Money copyWith({BigInt? amount, Currency? currency}) {
    if (currency != null && amount == null && currency.decimals != this.currency.decimals) {
      return Money(
        _transformAmount(this.amount, this.currency.decimals, currency.decimals),
        currency,
      );
    }

    return Money(amount ?? this.amount, currency ?? this.currency);
  }

  /// Creates new instance with the same currency and given [amount].
  Money _withAmount(BigInt amount) => Money(amount, currency);

  void _assertSameCurrency(Money other, [String? message]) {
    if (currency != other.currency) {
      throw ArgumentError(message ?? "Cannot operate with money values in different currencies.");
    }
  }

  BigInt _transformAmount(BigInt source, int sourceDecimals, int targetDecimals) {
    if (sourceDecimals == targetDecimals) {
      return source;
    }

    if (sourceDecimals > targetDecimals) {
      return parseFixed(
        formatFixed(source, sourceDecimals).withMaxDecimals(targetDecimals),
        targetDecimals,
      );
    } else {
      return parseFixed(formatFixed(source, sourceDecimals), targetDecimals);
    }
  }

  @override
  int get hashCode => amount.hashCode ^ currency.hashCode;

  // Added this to reduce the hops we do to convert Money to double
  // for fiat conversion and display
  double toDouble() => amount / multiplierOf(currency.decimals);

  @override
  String toString() => formatFixed(amount, currency.decimals);

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
        amount,
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
