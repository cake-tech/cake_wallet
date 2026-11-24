import "dart:async";

import "package:bloc/bloc.dart";
import "package:cake_wallet/exchange/assets/provider_asset_index.dart";
import "package:cake_wallet/exchange/assets/provider_listing.dart";
import "package:cake_wallet/exchange/assets/swap_asset_merger.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_groups.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/external_currency.dart";
import "package:cw_core/provider_asset.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:meta/meta.dart";

part "swap_currency_state.dart";

class SwapCurrencyCubit extends Cubit<SwapCurrencyState> {
  SwapCurrencyCubit({required ExchangeProviderRegistry registry})
    : _registry = registry,
      super(const SwapCurrenciesNotLoaded()) {
    unawaited(loadCurrenciesFromDb().then((_) => refreshCurrencies()));
  }

  static const excludedCurrencies = [CryptoCurrency.btt];

  static const _listingTimeout = Duration(seconds: 60);

  final ExchangeProviderRegistry _registry;

  /// The current list, the built-in currencies until the stored ones load
  List<CryptoCurrency> get currencies => switch (state) {
    SwapCurrenciesWithList(:final currencies) => currencies,
    SwapCurrenciesNotLoaded() => _withoutExcluded(CryptoCurrency.all),
  };

  static List<CryptoCurrency> _withoutExcluded(List<CryptoCurrency> currencies) =>
      currencies.where((c) => !excludedCurrencies.contains(c)).toList();

  Future<void> loadCurrenciesFromDb() async {
    try {
      final tokens = [
        ...await TokenUtilities.loadEvmTokensForSwap(),
        ...await TokenUtilities.loadSolTokensForSwap(),
        ...await TokenUtilities.loadTronTokensForSwap(),
      ];
      ProviderAssetIndex.instance.update(rows: await ProviderAsset.getAll(), tokens: tokens);
      emit(
        SwapCurrenciesRefreshing(
          known: [
            ...CryptoCurrency.all,
            for (final token in tokens)
              if (!_listContainsToken(CryptoCurrency.all, token)) token,
          ],
          external: await ExternalCurrency.getAll(),
        ),
      );
    } catch (e, s) {
      printV("loading the swap currencies failed: $e\n$s");
      emit(SwapCurrenciesRefreshing(known: CryptoCurrency.all, external: const []));
    }
  }

  Future<void> refreshCurrencies() async {
    if (state case SwapCurrenciesWithList(:final known, :final external)) {
      if (state is SwapCurrenciesLoaded) {
        emit(SwapCurrenciesRefreshing(known: known, external: external));
      }

      try {
        final results = await Future.wait(_registry.allProviders.map(_fetchListings));
        final listings = {
          for (int i = 0; i < _registry.allProviders.length; i++)
            _registry.allProviders[i]: results[i],
        };

        final matched = _match(
          mergeListings([for (final list in listings.values) ...?list]),
          known: known,
          external: external,
          complete:
              listings.values.every((list) => list != null) &&
              listings.length == _registry.registeredProviders.length,
        );

        await ExternalCurrency.saveAll(matched.changed);
        await ProviderAsset.replace({
          for (final MapEntry(key: provider, value: list) in listings.entries)
            if (list != null)
              provider.raw: [
                for (final row in matched.rows)
                  if (row.provider == provider.raw) row,
              ],
        }, renamedKeys: matched.renamed);
        ProviderAssetIndex.instance.update(rows: await ProviderAsset.getAll());
        emit(SwapCurrenciesLoaded(known: known, external: matched.external));
      } catch (e, s) {
        printV("refreshing the swap currencies failed: $e\n$s");
        emit(SwapCurrenciesLoaded(known: known, external: external));
      }
    }
  }

  Future<List<ProviderListing>?> _fetchListings(ExchangeProviderDescription provider) async {
    try {
      return await _registry.getProvider(provider).fetchListings().timeout(_listingTimeout);
    } catch (e, s) {
      printV("fetching the asset list from ${provider.title} failed: $e\n$s");
      return null;
    }
  }

  /// Matches the providers' assets to the known currencies and the stored ones. A built-in
  /// currency that looks the same wins, a stored one is kept, a new one is stored. Stored ones
  /// nobody lists anymore are disabled once every provider answered, the stale ones always
  static ({
    List<ExternalCurrency> external,
    List<ExternalCurrency> changed,
    List<ProviderAsset> rows,
    Map<String, String> renamed,
  })
  _match(
    List<SwapAsset> assets, {
    required List<CryptoCurrency> known,
    required List<ExternalCurrency> external,
    required bool complete,
  }) {
    final knownKeys = {for (final c in known) ProviderAssetIndex.instance.keyOf(c)};
    final knownByTitle = <(String, String), Set<String>>{};
    for (final currency in known) {
      (knownByTitle[ProviderAssetIndex.titleKeyOf(currency)] ??= {}).add(
        ProviderAssetIndex.instance.keyOf(currency),
      );
    }

    final stored = {for (final currency in external) currency.assetKey: currency};
    final storedByTitle = <(String, String), Set<String>>{};
    for (final currency in external) {
      (storedByTitle[ProviderAssetIndex.titleKeyOf(currency)] ??= {}).add(currency.assetKey);
    }

    final contractsByTitle = <(String, String), int>{};
    for (final asset in assets.where((asset) => asset.hasContract)) {
      contractsByTitle[asset.titleKey] = (contractsByTitle[asset.titleKey] ?? 0) + 1;
    }

    final changed = Set<ExternalCurrency>.identity();
    final renamed = <String, String>{};

    String? keyFor(SwapAsset asset) {
      final isOnlyContract = asset.hasContract && contractsByTitle[asset.titleKey] == 1;

      if (knownKeys.contains(asset.assetKey)) {
        return asset.assetKey;
      }

      // a built-in currency that looks the same wins. one whose contract Cake doesn't know takes
      // the only listed contract, the other lookalikes are left out
      if (knownByTitle[asset.titleKey] case final keys?) {
        return switch (asset.hasContract) {
          false when keys.length == 1 => keys.single,
          true when isOnlyContract && keys.contains(asset.symbolKey) => asset.symbolKey,
          _ => null,
        };
      }

      if (stored[asset.assetKey] case final currency?) {
        if (_enrich(currency, asset)) {
          changed.add(currency);
        }
        return asset.assetKey;
      }

      // without a contract it can only be the stored asset of its title, when there's one
      if (!asset.hasContract) {
        switch (storedByTitle[asset.titleKey]) {
          case final keys? when keys.length == 1:
            if (_enrich(stored[keys.single]!, asset)) {
              changed.add(stored[keys.single]!);
            }
            return keys.single;
          case final keys? when keys.length > 1:
            return null;
        }
      }

      // a stored asset that was only known by its title learns its contract and keeps its id
      if (stored[asset.symbolKey] case final currency? when isOnlyContract) {
        stored.remove(asset.symbolKey);
        storedByTitle[asset.titleKey]?.remove(asset.symbolKey);
        currency
          ..assetKey = asset.assetKey
          ..contractAddress = asset.contractAddress;
        _enrich(currency, asset);
        stored[asset.assetKey] = currency;
        (storedByTitle[asset.titleKey] ??= {}).add(asset.assetKey);
        renamed[asset.symbolKey] = asset.assetKey;
        changed.add(currency);
        return asset.assetKey;
      }

      final created = ExternalCurrency(
        assetKey: asset.assetKey,
        title: asset.title,
        tag: asset.tag,
        fullName: asset.fullName,
        contractAddress: asset.contractAddress,
        iconUrl: asset.iconUrl,
        groups: asset.isStock ? const {CurrencyGroups.tokenizedStock} : const {},
      );
      if (!_canBeHeld(created)) {
        return null;
      }
      stored[asset.assetKey] = created;
      (storedByTitle[asset.titleKey] ??= {}).add(asset.assetKey);
      changed.add(created);
      return asset.assetKey;
    }

    final rows = <ProviderAsset>[];
    for (final asset in assets) {
      final key = keyFor(asset);
      for (final listing in asset.listings) {
        // a listing without a contract only names a title, a built-in currency with it wins
        final listingKey = listing.hasContract
            ? key
            : switch (knownByTitle[asset.titleKey]) {
                final keys? when keys.length == 1 => keys.single,
                _ => key,
              };
        if (listingKey != null) {
          rows.add(listing.toAsset(listingKey));
        }
      }
    }
    final listed = {for (final row in rows) row.assetKey};

    for (final currency in stored.values) {
      // covered by a known currency since it was stored, or held by a wallet that can't hold it
      final isStale =
          !_canBeHeld(currency) ||
          knownKeys.contains(currency.assetKey) ||
          knownByTitle.containsKey(ProviderAssetIndex.titleKeyOf(currency));
      final isListed = !isStale && listed.contains(currency.assetKey);
      if (currency.disabled == isListed && (isListed || complete || isStale)) {
        currency.disabled = !isListed;
        changed.add(currency);
      }
    }

    return (
      external: stored.values.toList(),
      changed: changed.toList(),
      rows: rows,
      renamed: renamed,
    );
  }

  /// Fills what the earlier providers didn't have, returns whether anything changed
  static bool _enrich(ExternalCurrency currency, SwapAsset asset) {
    var changed = false;
    if (currency.iconUrl == null && asset.iconUrl != null) {
      currency.iconUrl = asset.iconUrl;
      changed = true;
    }
    if (currency.fullName == null && asset.fullName != null) {
      currency.fullName = asset.fullName;
      changed = true;
    }
    if (asset.isStock && !currency.groups.contains(CurrencyGroups.tokenizedStock)) {
      currency.groups = {...currency.groups, CurrencyGroups.tokenizedStock};
      changed = true;
    }
    return changed;
  }

  /// A token on a chain whose wallets only hold the native coin, like a BRC-20 on Bitcoin, would
  /// be spent as fees or lost by that wallet, so it isn't offered at all
  static bool _canBeHeld(ExternalCurrency currency) =>
      currency.isNative ||
      switch (cryptoCurrencyOrTokenToWalletType(currency)) {
        final type? => hasTokens(type),
        null => true,
      };

  static bool _listContainsToken(List<CryptoCurrency> list, CryptoCurrency token) =>
      list.any((item) {
        if (item is Erc20Token && token is Erc20Token) {
          return item.contractAddress.toLowerCase() == token.contractAddress.toLowerCase();
        }
        if (item is SPLToken && token is SPLToken) {
          return item.mintAddress.toLowerCase() == token.mintAddress.toLowerCase();
        }
        if (item is TronToken && token is TronToken) {
          return item.contractAddress.toLowerCase() == token.contractAddress.toLowerCase();
        }
        return item.title.toUpperCase() == token.symbol.toUpperCase() &&
            (item.tag?.toUpperCase() == token.tag?.toUpperCase() || item.tag == null);
      });
}
