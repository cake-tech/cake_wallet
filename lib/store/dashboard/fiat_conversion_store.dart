import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cw_core/amount/money.dart";
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/currency.dart";
import 'package:mobx/mobx.dart';

part 'fiat_conversion_store.g.dart';

class FiatConversionStore = FiatConversionStoreBase with _$FiatConversionStore;

abstract class FiatConversionStoreBase with Store {
  FiatConversionStoreBase() : prices = ObservableMap<CryptoCurrency, double>();

  @observable
  ObservableMap<CryptoCurrency, double> prices;

  // TODO refactor after charts is merged
  Money convert(Money amount, Currency target) {
    if (amount.currency is FiatCurrency && target is CryptoCurrency) {
      final price = prices[target];
      final convertedValue = amount.toDouble() / price!;
      return Money.parse(convertedValue, target);
    }
    else if (amount.currency is CryptoCurrency && target is FiatCurrency) {
      final price = prices[amount.currency];
      final convertedValue = amount.toDouble() * price!;
      return Money.parse(convertedValue, target);
    }
    throw ArgumentError("for now, only fiat <-> crypto conversions are supported");
  }
}
