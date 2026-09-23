import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/amount/money_double.dart";
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/currency/fiat_currency.dart";
import 'package:mobx/mobx.dart';

part 'fiat_conversion_store.g.dart';

class FiatConversionStore = FiatConversionStoreBase with _$FiatConversionStore;

abstract class FiatConversionStoreBase with Store {
  FiatConversionStoreBase() : prices = ObservableMap<CryptoCurrency, double>();

  @observable
  ObservableMap<CryptoCurrency, double> prices;

  ExchangeRate getExchangeRate(CryptoCurrency crypto, FiatCurrency fiat, double? price) {
    final quote = price?.toMoney(fiat) ?? Money.zero(fiat);
    return ExchangeRate(base: crypto, quote: quote);
  }
}
