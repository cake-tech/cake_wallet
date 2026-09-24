import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class ExchangeLimits {
  ExchangeLimits({this.min, this.max}) {
    if (min != null && max != null && min!.currency != max!.currency) {
      throw ArgumentError("min and max must have the same currency when creating ExchangeLimits");
    }
  }

  final Money? min;
  final Money? max;

  // warning: if both min and max are null, this returns true.
  // this is intended behavior as there can be no limit for the swap
  bool isWithinLimit(Money amount) {
    final targetCurrency = min?.currency ?? max?.currency;

    if (targetCurrency != null && amount.currency != targetCurrency) {
      throw ArgumentError("cannot check limit for different currency");
    }

    final isAboveMin = min == null || amount > min!;
    final isBelowMax = max == null || amount < max!;

    return isAboveMin && isBelowMax;
  }
}
