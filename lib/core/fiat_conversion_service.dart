import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/model/charts/price_api_client.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";

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
  }) async {
    final resolved = _overrideCryptoCurrency(crypto);

    // TODO(rafael): use actual price conversion for spark stables instead of
    // hardcoded 1 token = 1 usd
    final isSparkStable = bitcoin?.isDefaultSparkStablecoin(resolved) ?? false;
    if (isSparkStable && fiat == FiatCurrency.usd) return 1.0;

    final Currency from = isSparkStable ? FiatCurrency.usd : resolved;

    return double.parse((await PriceApiClient.getLatestPrice(
          LatestPriceRequest(from: from, to: fiat),
          torOnly: torOnly,
        ))
            ?.quote
            .toString() ??
        "0");
  }
}
