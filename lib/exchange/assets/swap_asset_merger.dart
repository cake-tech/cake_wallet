import "package:cake_wallet/exchange/assets/provider_listing.dart";

/// One asset as the providers list it
class SwapAsset {
  const SwapAsset(this.listings);

  /// Every provider's listing of the asset, the first one naming it
  final List<ProviderListing> listings;

  String get assetKey => listings.first.assetKey;

  String get symbolKey => listings.first.symbolKey;

  (String, String) get titleKey => listings.first.titleKey;

  String get tag => listings.first.tag;

  String get title => listings.first.title;

  String? get contractAddress => listings.first.normalizedContract;

  bool get hasContract => listings.first.hasContract;

  String? get fullName => listings.map((listing) => listing.fullName).nonNulls.firstOrNull;

  String? get iconUrl => listings.map((listing) => listing.iconUrl).nonNulls.firstOrNull;

  bool get isStock => listings.any((listing) => listing.isStock);
}

List<SwapAsset> mergeListings(List<ProviderListing> listings) {
  final byKey = <String, List<ProviderListing>>{};
  for (final listing in listings.where((listing) => !listing.hasSymbolKey)) {
    (byKey[listing.assetKey] ??= []).add(listing);
  }

  final keysByTitle = <(String, String), List<String>>{};
  for (final MapEntry(:key, :value) in byKey.entries) {
    (keysByTitle[value.first.titleKey] ??= []).add(key);
  }

  for (final listing in listings.where((listing) => listing.hasSymbolKey)) {
    switch (keysByTitle[listing.titleKey]) {
      case [final key]:
        byKey[key]!.add(listing);
      case null:
        (byKey[listing.assetKey] ??= []).add(listing);
    }
  }

  return [for (final group in byKey.values) SwapAsset(group)];
}
