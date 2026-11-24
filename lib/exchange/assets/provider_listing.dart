import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cw_core/provider_asset.dart";
import "package:cw_core/swap_networks.dart";

/// One asset from a provider's asset list, with the provider's own identifiers for it.
class ProviderListing {
  const ProviderListing({
    required this.provider,
    required this.tag,
    required this.ticker,
    required this.network,
    String? symbol,
    this.contractAddress,
    this.assetId,
    this.decimals,
    String? fullName,
    String? iconUrl,
    this.isNative = false,
    this.isStock = false,
  }) : _symbol = symbol,
       _fullName = fullName,
       _iconUrl = iconUrl;

  final ExchangeProviderDescription provider;

  /// Cake's tag for the network, see [SwapNetworks.tagFor]
  final String tag;

  /// What the provider calls the asset in its requests
  final String ticker;

  /// What the provider calls the network in its requests
  final String network;

  final String? _symbol;
  final String? contractAddress;
  final String? assetId;
  final int? decimals;
  final String? _fullName;
  final String? _iconUrl;

  /// Set by providers that flag native coins, the rest are detected by ticker
  final bool isNative;
  final bool isStock;

  static final _evmAddress = RegExp(r"^0x[0-9a-fA-F]{40}$");

  bool get hasContract => normalizedContract != null;

  /// EVM addresses are case-insensitive and providers mix checksummed and lowercase ones, the
  /// other chains' addresses are case-sensitive
  String? get normalizedContract => switch (contractAddress?.trim()) {
    final contract? when _evmAddress.hasMatch(contract) => contract.toLowerCase(),
    final contract? when contract.isNotEmpty => contract,
    _ => null,
  };

  String? get fullName => (_fullName?.trim().isEmpty ?? true) ? null : _fullName!.trim();

  String? get iconUrl => (_iconUrl?.trim().isEmpty ?? true) ? null : _iconUrl!.trim();

  bool get _isNative => !hasContract && (isNative || SwapNetworks.isNativeTicker(tag, symbol));

  String get symbol => (_symbol ?? ticker).trim().toUpperCase();

  String get title => _isNative ? SwapNetworks.nativeTitle(tag) : symbol;

  /// Keyed like `CryptoCurrency.assetKey`, so a listing of a known currency finds it
  String get assetKey => switch (normalizedContract) {
    final contract? => "$tag/$contract",
    null when _isNative => "$tag/native",
    null => symbolKey,
  };

  /// The key a token with this title has while its contract isn't known
  String get symbolKey => "$tag/symbol:$title";

  bool get hasSymbolKey => assetKey == symbolKey;

  /// Looks assets up by name, like `ProviderAssetIndex.titleKeyOf`
  (String, String) get titleKey => (tag, title);

  ProviderAsset toAsset(String assetKey) => ProviderAsset(
    provider: provider.raw,
    assetKey: assetKey,
    ticker: ticker,
    network: network,
    assetId: assetId,
    decimals: decimals,
  );
}
