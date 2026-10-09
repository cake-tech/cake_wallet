import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/currency_for_wallet_type.dart";
import 'package:mobx/mobx.dart';

part 'fiat_conversion_store.g.dart';

class FiatConversionStore = FiatConversionStoreBase with _$FiatConversionStore;

abstract class FiatConversionStoreBase with Store {
  FiatConversionStoreBase() : prices = ObservableMap<CryptoCurrency, double>();

  @observable
  ObservableMap<CryptoCurrency, double> prices;

  // The price API answers 0 for a symbol it does not know, so no positive price means unpriced
  bool isUnpricedAddedNetworkCurrency(CryptoCurrency currency) =>
      EvmNativeCurrencies.isAddedNetworkCurrency(currency) && (prices[currency] ?? 0) <= 0;
}
