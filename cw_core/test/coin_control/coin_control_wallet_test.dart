import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:flutter_test/flutter_test.dart";

import "fake_coin_control_stores.dart";
import "fake_coin_control_wallet.dart";

Unspent coin(String hash, int vout, {int value = 1000}) =>
    Unspent("addr-$hash", hash, value, vout, null);

void main() {
  late FakeFrozenCoinsStore store;
  late FakeCoinControlWallet wallet;

  final a = coin("aa", 0, value: 100);
  final b = coin("bb", 0, value: 200);
  final c = coin("cc", 0, value: 300);

  setUp(() {
    store = FakeFrozenCoinsStore();
    wallet = FakeCoinControlWallet(
      id: "wallet-a",
      unspents: [a, b, c],
      frozenCoinsStore: store,
    );
  });

  group("spendableCoins", () {
    test("defaults to an all-outputs selection when none is given", () async {
      final spendable = await wallet.spendableCoins();
      expect(spendable.map((coin) => coin.id), [a.id, b.id, c.id]);
    });

    test("returns only the selected outputs", () async {
      final spendable = await wallet.spendableCoins(selection: SpecificCoinSelection({a.id, c.id}));
      expect(spendable.map((coin) => coin.id), [a.id, c.id]);
    });

    test("returns nothing for an empty selection", () async {
      final spendable =
          await wallet.spendableCoins(selection: SpecificCoinSelection(const <String>{}));
      expect(spendable, isEmpty);
    });

    test("excludes a frozen output even under an all-outputs selection", () async {
      // The rule the previous implementation dropped in two fee estimators.
      await wallet.setFrozen(b.id, true);

      final spendable = await wallet.spendableCoins();
      expect(spendable.map((coin) => coin.id), [a.id, c.id]);
    });

    test("excludes a frozen output even when it is explicitly selected", () async {
      await wallet.setFrozen(b.id, true);

      final spendable = await wallet.spendableCoins(selection: SpecificCoinSelection({a.id, b.id}));
      expect(spendable.map((coin) => coin.id), [a.id]);
    });

    test("unfreezing makes an output spendable again", () async {
      await wallet.setFrozen(b.id, true);
      await wallet.setFrozen(b.id, false);

      final spendable = await wallet.spendableCoins();
      expect(spendable.map((coin) => coin.id), [a.id, b.id, c.id]);
    });

    test("reads the frozen set once per call, not once per output", () async {
      final counting = _CountingStore(store);
      final counted = FakeCoinControlWallet(
        id: "wallet-a",
        unspents: List.generate(50, (i) => coin("tx$i", 0)),
        frozenCoinsStore: counting,
      );

      await counted.spendableCoins();

      // Transaction building calls this repeatedly per transaction, so a read
      // per output would be n * passes queries against the store.
      expect(counting.frozenIdsCalls, 1);
    });

    test("another wallet's frozen record does not affect this one", () async {
      await store.setFrozen("wallet-b", b.id, true);

      final spendable = await wallet.spendableCoins();
      expect(spendable, hasLength(3));
    });

    test("survives a refresh that replaces every Unspent instance", () async {
      await wallet.setFrozen(b.id, true);
      wallet.unspents = [coin("aa", 0), coin("bb", 0), coin("cc", 0)];

      final spendable = await wallet.spendableCoins(selection: SpecificCoinSelection({a.id, b.id}));
      expect(spendable.map((coin) => coin.id), [a.id]);
    });
  });

  group("spendableCoins with a coin type", () {
    late FakeCoinControlWallet mixedWallet;
    final mweb = coin("mweb-out", 0);
    final regular = coin("regular-out", 0);

    setUp(() {
      mixedWallet = FakeCoinControlWallet(
        id: "wallet-a",
        unspents: [regular, mweb],
        frozenCoinsStore: store,
        coinTypeOf: (coin) =>
            coin.hash.startsWith("mweb") ? UnspentCoinType.mweb : UnspentCoinType.nonMweb,
      );
    });

    test("any accepts every kind", () async {
      final spendable = await mixedWallet.spendableCoins(coinType: UnspentCoinType.any);
      expect(spendable, hasLength(2));
    });

    test("narrows to the requested kind", () async {
      final spendable = await mixedWallet.spendableCoins(
        coinType: UnspentCoinType.nonMweb,
      );
      expect(spendable.map((coin) => coin.id), [regular.id]);
    });

    test("an all-outputs selection cannot defeat the coin type", () async {
      // Select-all under a constraint must still not produce a transaction the
      // flow cannot make: the constraint is applied by this method, not by the
      // selection, and not by filtering the list the user was shown.
      final spendable = await mixedWallet.spendableCoins(
        coinType: UnspentCoinType.mweb,
      );
      expect(spendable.map((coin) => coin.id), [mweb.id]);
    });

    test("an explicit selection of the wrong kind yields nothing", () async {
      final spendable = await mixedWallet.spendableCoins(
        selection: SpecificCoinSelection({mweb.id}),
        coinType: UnspentCoinType.nonMweb,
      );
      expect(spendable, isEmpty);
    });

    test("frozen still wins over a matching coin type", () async {
      await mixedWallet.setFrozen(regular.id, true);

      final spendable = await mixedWallet.spendableCoins(
        coinType: UnspentCoinType.nonMweb,
      );
      expect(spendable, isEmpty);
    });
  });

  group("frozenBalance", () {
    test("is zero when nothing is frozen", () async {
      expect(await wallet.frozenBalance(), 0);
    });

    test("sums only the frozen outputs", () async {
      await wallet.setFrozen(a.id, true);
      await wallet.setFrozen(c.id, true);

      expect(await wallet.frozenBalance(), 400);
    });

    test("does not double count", () async {
      await wallet.setFrozen(a.id, true);
      await wallet.setFrozen(a.id, true);

      expect(await wallet.frozenBalance(), 100);
    });

    test("ignores a record for an output that has since been spent", () async {
      // Derived by matching records against the live output list, so a leftover
      // record contributes nothing and pruning is not a correctness concern.
      await wallet.setFrozen(a.id, true);
      wallet.unspents = [b, c];

      expect(await wallet.frozenBalance(), 0);
    });

    test("ignores another wallet's frozen records", () async {
      await store.setFrozen("wallet-b", a.id, true);
      expect(await wallet.frozenBalance(), 0);
    });
  });
}

class _CountingStore implements FrozenCoinsStore {
  _CountingStore(this._inner);

  final FrozenCoinsStore _inner;
  int frozenIdsCalls = 0;

  @override
  Future<Set<String>> frozenIds(String walletId) {
    frozenIdsCalls++;
    return _inner.frozenIds(walletId);
  }

  @override
  Future<void> setFrozen(String walletId, String id, bool frozen) =>
      _inner.setFrozen(walletId, id, frozen);

  @override
  Future<void> deleteWallet(String walletId) => _inner.deleteWallet(walletId);
}
