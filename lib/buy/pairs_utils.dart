import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/crypto_currency.dart';

class TradePair<T, U> {
  TradePair({required this.from, required this.to});

  final T from;
  final U to;
}

List<TradePair<CryptoCurrency, FiatCurrency>> supportedCryptoToFiatPairs({
  required List<CryptoCurrency> notSupportedCrypto,
  required List<FiatCurrency> notSupportedFiat,
}) {
  final supportedCrypto =
      CryptoCurrency.all.where((crypto) => !notSupportedCrypto.contains(crypto)).toList();
  final supportedFiat = FiatCurrency.all.where((fiat) => !notSupportedFiat.contains(fiat)).toList();

  return supportedCrypto
      .expand((crypto) => supportedFiat
          .map((fiat) => TradePair<CryptoCurrency, FiatCurrency>(from: crypto, to: fiat)))
      .toList();
}

List<TradePair<FiatCurrency, CryptoCurrency>> supportedFiatToCryptoPairs({
  required List<FiatCurrency> notSupportedFiat,
  required List<CryptoCurrency> notSupportedCrypto,
}) {
  final supportedFiat = FiatCurrency.all.where((fiat) => !notSupportedFiat.contains(fiat)).toList();
  final supportedCrypto =
      CryptoCurrency.all.where((crypto) => !notSupportedCrypto.contains(crypto)).toList();

  return supportedFiat
      .expand((fiat) => supportedCrypto
          .map((crypto) => TradePair<FiatCurrency, CryptoCurrency>(from: fiat, to: crypto)))
      .toList();
}
