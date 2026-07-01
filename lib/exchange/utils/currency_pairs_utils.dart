import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cw_core/crypto_currency.dart';

List<ExchangePair> supportedPairs(List<CryptoCurrency> notSupported) {
  final supportedCurrencies =
      CryptoCurrency.all.where((element) => !notSupported.contains(element)).toList();

  return supportedCurrencies
      .map((i) => supportedCurrencies.map((k) => ExchangePair(from: i, to: k, reverse: true)))
      .expand((i) => i)
      .toList();
}
