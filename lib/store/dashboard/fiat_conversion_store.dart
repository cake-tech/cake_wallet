import "package:cake_wallet/core/fiat_conversion_service.dart";
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
  Future<Money> convert(Money amount, Currency target) async {
    if (amount.currency is FiatCurrency && target is CryptoCurrency) {
      if(prices[target] == null) {
        prices[target] = await FiatConversionService.fetchPrice(
            crypto: target, fiat: amount.currency as FiatCurrency, torOnly: false);
      }
      final price = prices[target];
      final convertedValue = double.parse(amount.toString()) / price!;
      return Money.safeParse(convertedValue, target);
    }
    else if (amount.currency is CryptoCurrency && target is FiatCurrency) {
      if(prices[amount.currency] == null) {
        prices[amount.currency as CryptoCurrency] = await FiatConversionService.fetchPrice(
            crypto: amount.currency as CryptoCurrency, fiat: target, torOnly: false);
      }
      final price = prices[amount.currency];

      final convertedValue = double.parse(amount.toString()) * price!;
      return Money.safeParse(convertedValue, target);
    }
    throw ArgumentError("for now, only fiat <-> crypto conversions are supported");
  }
}
