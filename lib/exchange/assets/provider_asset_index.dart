import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/provider_asset.dart";

class ProviderAssetIndex {
  ProviderAssetIndex();

  static ProviderAssetIndex instance = ProviderAssetIndex();

  Map<int, Map<String, ProviderAsset>> _rows = const {};
  Map<String, String> _contractKeys = const {};

  void update({required Iterable<ProviderAsset> rows, Iterable<CryptoCurrency>? tokens}) {
    final byProvider = <int, Map<String, ProviderAsset>>{};
    for (final row in rows) {
      (byProvider[row.provider] ??= {})[row.assetKey] = row;
    }
    _rows = byProvider;

    if (tokens != null) {
      _contractKeys = {for (final token in tokens) token.symbolKey: token.assetKey};
    }
  }

  ProviderAsset? find(ExchangeProviderDescription provider, CryptoCurrency currency) =>
      _rows[provider.raw]?[keyOf(currency)];

  String keyOf(CryptoCurrency currency) => _contractKeys[currency.assetKey] ?? currency.assetKey;

  static (String, String) titleKeyOf(CryptoCurrency currency) =>
      (currency.assetNetwork, currency.title.toUpperCase());
}
