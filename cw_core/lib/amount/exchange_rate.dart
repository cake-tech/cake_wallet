import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency.dart';

class ExchangeRate {
  const ExchangeRate({required this.base, required this.quote});

  /// The currency being priced (e.g. BTC in a BTC/USD pair).
  final Currency base;

  /// The price of one whole unit of [base], in the quote currency
  /// (e.g. 45000 USD in a BTC/USD pair).
  final Money quote;

  /// Converts [amount] between the base and quote currencies.
  ///
  /// Results are truncated toward zero.
  ///
  /// Throws an [ArgumentError] if [amount]'s currency is not part of
  /// this pair.
  Money convert(Money amount) {
    if (base == quote.currency && base == amount.currency) {
      return amount;
    }

    if (amount.currency == base) {
      final scale = BigInt.from(10).pow(amount.decimals);

      return quote.isZero
          ? Money.zero(quote.currency)
          : Money(amount.amount * quote.amount ~/ scale, quote.currency, quote.decimals);
    }

    if (amount.currency == quote.currency) {
      if (quote.isZero) {
        return Money.zero(base);
      }

      final numerator = amount.amount * BigInt.from(10).pow(base.decimals + quote.decimals);
      final denominator = quote.amount * BigInt.from(10).pow(amount.decimals);

      return Money(numerator ~/ denominator, base);
    }

    throw ArgumentError(
      "Unable to convert ${amount.currency.symbol} in ${base.symbol}/${quote.currency.symbol} pair",
    );
  }
}
