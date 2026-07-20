import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency.dart';

class ExchangeRate {
  /// The currency being priced (e.g. BTC in a BTC/USD pair).
  final Currency base;

  /// The price of one whole unit of [base], in the quote currency
  /// (e.g. 45000 USD in a BTC/USD pair).
  final Money quote;

  const ExchangeRate({required this.base, required this.quote});

  /// Converts [amount] between the base and quote currencies.
  ///
  /// Results are truncated toward zero.
  ///
  /// Throws an [ArgumentError] if [amount]'s currency is not part of
  /// this pair.
  Money convert(Money amount) {
    if (base == quote.currency && base == amount.currency) return amount;

    final scale = BigInt.from(10).pow(base.decimals);

    if (amount.currency == base) {
      if (quote.isZero) return Money.zero(quote.currency);

      return Money(amount.amount * quote.amount ~/ scale, quote.currency);
    }

    if (amount.currency == quote.currency) {
      if (quote.isZero) return Money.zero(base);

      return Money(amount.amount * scale ~/ quote.amount, base);
    }

    throw ArgumentError(
        "Unable to convert ${amount.currency.symbol} in ${base.symbol}/${quote.currency.symbol} pair");
  }
}
