import "package:cake_wallet/new-ui/model/charts/price_api_client.dart";
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

/// Override specific [CryptoCurrency] to fix its price to the price of another
/// e.g. nDEPS should have the same price as DEPS, but only DEPS is tracked
CryptoCurrency _overrideCryptoCurrency(CryptoCurrency crypto) {
  if (crypto.title == CryptoCurrency.ndeps.title) return CryptoCurrency.deps;
  return crypto;
}

class FiatConversionService {
  static Future<double> fetchPrice({
    required CryptoCurrency crypto,
    required FiatCurrency fiat,
    required bool torOnly,
  }) async =>
      (await PriceApiClient.getLatestPrice(
        LatestPriceRequest(
          from: _overrideCryptoCurrency(crypto),
          to: fiat,
        ),
        torOnly: torOnly,
      ))
          ?.quote
          .toDouble() ??
      0.0;
}
