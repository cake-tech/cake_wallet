import "dart:math";

import 'package:cw_core/amount/money.dart';
import "package:cw_core/amount/money_double.dart";
import 'package:cw_core/currency.dart';

class ExchangeRate {
  /// The currency being priced (e.g. BTC in a BTC/USD pair).
  final Currency base;

  /// The price of one whole unit of [base], in the quote currency
  /// (e.g. 45000 USD in a BTC/USD pair).
  final Money quote;

  const ExchangeRate({required this.base, required this.quote});

  /// Builds a pair from a raw [rate], the price of one whole [base] unit in
  /// [quoteCurrency].
  ///
  /// Returns null unless [rate] is a finite positive number. The quote only
  /// keeps [quoteCurrency]'s decimal places, so a small rate is stored
  /// flipped to keep its precision: 0.00002 USD per SHIB would round down
  /// to 0.00 USD, while the flipped 50000 SHIB per USD stores exactly.
  static ExchangeRate? tryFromDouble({
    required Currency base,
    required Currency quoteCurrency,
    required double rate,
  }) {
    if (rate <= 0.0 || !rate.isFinite) {
      return null;
    }

    final crossover = sqrt(pow(10.0, base.decimals - quoteCurrency.decimals));
    if (rate < crossover) {
      final quote = (1 / rate).tryToMoney(base);
      return quote == null ? null : ExchangeRate(base: quoteCurrency, quote: quote);
    }

    final quote = rate.tryToMoney(quoteCurrency);
    return quote == null ? null : ExchangeRate(base: base, quote: quote);
  }

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
