import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency.dart';

class ExchangeRate {
  /// The currency being priced (e.g. BTC in a BTC/USD pair).
  final Currency baseCurrency;

  /// The price of one whole unit of [baseCurrency], in the quote currency
  /// (e.g. 45000 USD in a BTC/USD pair).
  final Money quote;

  const ExchangeRate({required this.baseCurrency, required this.quote});

  /// Converts [amount] between the base and quote currencies.
  ///
  /// Results are truncated toward zero.
  ///
  /// Throws an [ArgumentError] if [amount]'s currency is not part of
  /// this pair.
  Money convert(Money amount) {
    if (baseCurrency == quote.currency && baseCurrency == amount.currency) return amount;

    final scale = BigInt.from(10).pow(baseCurrency.decimals);

    if (amount.currency == baseCurrency) {
      if (quote.isZero) return Money.zero(quote.currency);

      return Money(amount.amount * quote.amount ~/ scale, quote.currency);
    }

    if (amount.currency == quote.currency) {
      if (quote.isZero) return Money.zero(baseCurrency);

      return Money(amount.amount * scale ~/ quote.amount, baseCurrency);
    }

    throw ArgumentError(
        "Unable to convert ${amount.currency.symbol} in ${baseCurrency.symbol}/${quote.currency.symbol} pair");
  }
}
