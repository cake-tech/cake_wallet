import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency.dart';

class ExchangeRate {
  final Currency baseCurrency;

  final Money quote;

  const ExchangeRate({required this.baseCurrency, required this.quote});

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
