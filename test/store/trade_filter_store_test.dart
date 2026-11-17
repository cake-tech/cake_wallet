import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/trade_filter_store.dart";
import "package:cake_wallet/view_model/dashboard/trade_list_item.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

class _Wallet extends Fake implements WalletBase {
  @override
  String get id => "wallet";

  @override
  WalletType get type => WalletType.litecoin;
}

class _App extends Fake implements AppStore {}

// xmrto and morphToken are long gone and all is the parent toggle, everything else must be
// wired into the store, or its trades never show
final _providers = ExchangeProviderDescription.values
    .where(
      (provider) => !{
        ExchangeProviderDescription.all,
        ExchangeProviderDescription.xmrto,
        ExchangeProviderDescription.morphToken,
      }.contains(provider),
    )
    .toList();

final _trades = [
  for (final provider in _providers)
    TradeListItem(
      trade: Trade(
        id: provider.title,
        provider: provider,
        state: TradeState.created,
        depositAmount: Money.parse("0.01", CryptoCurrency.btc),
        payoutAmount: Money.parse("1", CryptoCurrency.xmr),
        fundingAddress: "funding",
        payoutAddress: "payout",
        refundAddress: "refund",
        walletId: "wallet",
        accountIndex: 0,
      ),
      appStore: _App(),
      key: ValueKey(provider.title),
    ),
];

List<ExchangeProviderDescription> _shown(TradeFilterStore store) =>
    store.filtered(trades: _trades, wallet: _Wallet()).map((item) => item.trade.provider).toList();

void main() {
  group("TradeFilterStore", () {
    test("starts with every provider on", () {
      final store = TradeFilterStore();

      expect(store.enabledProvidersCount, _providers.length);
      expect(store.displayAllTrades, isTrue);
      expect(_shown(store), _providers);
    });

    test("toggling a provider turns only that one off, and back on", () {
      final store = TradeFilterStore();

      for (final provider in _providers) {
        store.toggleDisplayExchange(provider);

        expect(store.enabledProvidersCount, _providers.length - 1, reason: provider.title);
        expect(store.displayAllTrades, isFalse, reason: provider.title);

        store.toggleDisplayExchange(provider);

        expect(store.enabledProvidersCount, _providers.length, reason: provider.title);
        expect(store.displayAllTrades, isTrue, reason: provider.title);
      }
    });

    test("a provider that is off hides its own trades and no others", () {
      final store = TradeFilterStore();

      for (final provider in _providers) {
        store.toggleDisplayExchange(provider);

        expect(_shown(store), [..._providers]..remove(provider), reason: provider.title);

        store.toggleDisplayExchange(provider);
      }
    });

    test("all turns everything off when everything is on", () {
      final store = TradeFilterStore()..toggleDisplayExchange(ExchangeProviderDescription.all);

      expect(store.enabledProvidersCount, 0);
      expect(store.displayAllTrades, isFalse);
      expect(_shown(store), isEmpty);
    });

    test("all turns everything back on when any provider is off", () {
      final store = TradeFilterStore()
        ..toggleDisplayExchange(ExchangeProviderDescription.changeNow)
        ..toggleDisplayExchange(ExchangeProviderDescription.all);

      expect(store.enabledProvidersCount, _providers.length);
      expect(store.displayAllTrades, isTrue);
      expect(_shown(store), _providers);
    });
  });
}
