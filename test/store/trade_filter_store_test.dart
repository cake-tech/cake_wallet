import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/trade_filter_store.dart";
import "package:flutter_test/flutter_test.dart";

/// The store only reads `wallet` off the app store, and none of these cases
/// need one.
class _NoWallet extends Fake implements AppStore {
  @override
  Null get wallet => null;
}

void main() {
  group("TradeFilterStore filters", () {
    test("every provider it offers reports its own state", () {
      // The regression: providers past thorChain were missing from the lookup,
      // so they read as permanently off and their trades never showed.
      final store = TradeFilterStore(_NoWallet());
      final providers = store.filters.single.children;

      expect(providers, isNotEmpty);
      expect(
        providers.where((provider) => provider.value).length,
        providers.length,
        reason: "all providers start enabled, so none may read as off",
      );
    });

    test("the late-added providers are among them", () {
      final store = TradeFilterStore(_NoWallet());
      final keys = store.filters.single.children.map((child) => child.key);

      for (final provider in [
        ExchangeProviderDescription.letsExchange,
        ExchangeProviderDescription.stealthEx,
        ExchangeProviderDescription.xoSwap,
        ExchangeProviderDescription.swapTrade,
        ExchangeProviderDescription.swapsXyz,
        ExchangeProviderDescription.nearIntents,
      ]) {
        expect(keys, contains(provider.title));
      }
    });

    test("toggling one is reflected in what it reports", () {
      final store = TradeFilterStore(_NoWallet());

      for (final provider in store.filters.single.children) {
        store.toggleFilter(provider);

        final now = store.filters.single.children
            .firstWhere((child) => child.key == provider.key);

        expect(now.value, isFalse, reason: "${provider.key} did not turn off");

        store.toggleFilter(now);

        final back = store.filters.single.children
            .firstWhere((child) => child.key == provider.key);

        expect(back.value, isTrue, reason: "${provider.key} did not turn back on");
      }
    });

    test("the parent reports how many children are on", () {
      final store = TradeFilterStore(_NoWallet());
      final total = store.filters.single.children.length;

      expect(store.filters.single.enabledChildren, total);

      store.toggleFilter(store.filters.single.children.first);
      expect(store.filters.single.enabledChildren, total - 1);
    });

    test("setAllFilters is idempotent, unlike a toggle", () {
      final store = TradeFilterStore(_NoWallet());

      store.setAllFilters(value: false);
      expect(store.filters.single.enabledChildren, 0);

      // A toggle would turn everything back on here.
      store.setAllFilters(value: false);
      expect(store.filters.single.enabledChildren, 0);

      store.setAllFilters(value: true);
      store.setAllFilters(value: true);
      expect(store.filters.single.enabledChildren, store.filters.single.children.length);
    });
  });
}
