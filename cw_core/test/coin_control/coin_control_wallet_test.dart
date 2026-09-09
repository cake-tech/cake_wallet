import "package:cw_core/coin_control/coin_control_wallet.dart";
import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:flutter_test/flutter_test.dart";

import "fake_coin_control_stores.dart";

Unspent coin(String hash, int vout, {int value = 1000}) =>
    Unspent("addr-$hash", hash, value, vout, null);

/// The mixin asks only for a wallet id, so a double needs only that. Anything
/// more would be testing WalletBase rather than coin control.
class _FakeWallet with CoinControlWallet {
  _FakeWallet({
    required this.id,
    required this.unspents,
    required this.frozenCoinsStore,
    CoinNotesStore? coinNotesStore,
    this.coinTypeOf,
  }) : coinNotesStore = coinNotesStore ?? FakeCoinNotesStore();

  @override
  final String id;

  @override
  List<Unspent> unspents;

  @override
  final FrozenCoinsStore frozenCoinsStore;

  @override
  final CoinNotesStore coinNotesStore;

  /// Stands in for a chain that has more than one kind of output.
  final UnspentCoinType Function(Unspent coin)? coinTypeOf;

  int refreshCount = 0;

  @override
  Future<void> refreshUnspents() async => refreshCount++;

  @override
  bool allowsCoinType(Unspent coin, UnspentCoinType coinType) {
    if (coinTypeOf == null || coinType == UnspentCoinType.any) {
      return true;
    }
    return coinTypeOf!(coin) == coinType;
  }
}

void main() {
  late FakeFrozenCoinsStore store;
  late _FakeWallet wallet;

  final a = coin("aa", 0, value: 100);
  final b = coin("bb", 0, value: 200);
  final c = coin("cc", 0, value: 300);

  setUp(() {
    store = FakeFrozenCoinsStore();
    wallet = _FakeWallet(
      id: "wallet-a",
      unspents: [a, b, c],
      frozenCoinsStore: store,
    );
  });

  group("spendableCoins", () {
    test("returns everything under an all-outputs selection", () async {
      final spendable = await wallet.spendableCoins(const AllCoinSelection());
      expect(spendable.map((coin) => coin.id), [a.id, b.id, c.id]);
    });

    test("returns only the selected outputs", () async {
      final spendable = await wallet.spendableCoins(SpecificCoinSelection({a.id, c.id}));
      expect(spendable.map((coin) => coin.id), [a.id, c.id]);
    });

    test("returns nothing for an empty selection", () async {
      final spendable = await wallet.spendableCoins(SpecificCoinSelection(const <String>{}));
      expect(spendable, isEmpty);
    });

    test("excludes a frozen output even under an all-outputs selection", () async {
      // The rule the previous implementation dropped in two fee estimators.
      await wallet.setFrozen(b.id, true);

      final spendable = await wallet.spendableCoins(const AllCoinSelection());
      expect(spendable.map((coin) => coin.id), [a.id, c.id]);
    });

    test("excludes a frozen output even when it is explicitly selected", () async {
      await wallet.setFrozen(b.id, true);

      final spendable = await wallet.spendableCoins(SpecificCoinSelection({a.id, b.id}));
      expect(spendable.map((coin) => coin.id), [a.id]);
    });

    test("unfreezing makes an output spendable again", () async {
      await wallet.setFrozen(b.id, true);
      await wallet.setFrozen(b.id, false);

      final spendable = await wallet.spendableCoins(const AllCoinSelection());
      expect(spendable.map((coin) => coin.id), [a.id, b.id, c.id]);
    });

    test("a note alone does not make an output unspendable", () async {
      // Notes live in their own table for exactly this reason: there is no
      // path by which annotating an output can affect what is spendable.
      await wallet.saveNote(b.id, "just a note");

      final spendable = await wallet.spendableCoins(const AllCoinSelection());
      expect(spendable, hasLength(3));
    });

    test("reads the frozen set once per call, not once per output", () async {
      final counting = _CountingStore(store);
      final counted = _FakeWallet(
        id: "wallet-a",
        unspents: List.generate(50, (i) => coin("tx$i", 0)),
        frozenCoinsStore: counting,
      );

      await counted.spendableCoins(const AllCoinSelection());

      // Transaction building calls this repeatedly per transaction, so a read
      // per output would be n * passes queries against the store.
      expect(counting.frozenIdsCalls, 1);
    });

    test("another wallet's frozen record does not affect this one", () async {
      await store.setFrozen("wallet-b", b.id, true);

      final spendable = await wallet.spendableCoins(const AllCoinSelection());
      expect(spendable, hasLength(3));
    });

    test("survives a refresh that replaces every Unspent instance", () async {
      await wallet.setFrozen(b.id, true);
      wallet.unspents = [coin("aa", 0), coin("bb", 0), coin("cc", 0)];

      final spendable = await wallet.spendableCoins(SpecificCoinSelection({a.id, b.id}));
      expect(spendable.map((coin) => coin.id), [a.id]);
    });
  });

  group("spendableCoins with a coin type", () {
    late _FakeWallet mixedWallet;
    final mweb = coin("mweb-out", 0);
    final regular = coin("regular-out", 0);

    setUp(() {
      mixedWallet = _FakeWallet(
        id: "wallet-a",
        unspents: [regular, mweb],
        frozenCoinsStore: store,
        coinTypeOf: (coin) =>
            coin.hash.startsWith("mweb") ? UnspentCoinType.mweb : UnspentCoinType.nonMweb,
      );
    });

    test("any accepts every kind", () async {
      final spendable =
          await mixedWallet.spendableCoins(const AllCoinSelection(), coinType: UnspentCoinType.any);
      expect(spendable, hasLength(2));
    });

    test("narrows to the requested kind", () async {
      final spendable = await mixedWallet.spendableCoins(
        const AllCoinSelection(),
        coinType: UnspentCoinType.nonMweb,
      );
      expect(spendable.map((coin) => coin.id), [regular.id]);
    });

    test("an all-outputs selection cannot defeat the coin type", () async {
      // Select-all under a constraint must still not produce a transaction the
      // flow cannot make: the constraint is applied by this method, not by the
      // selection, and not by filtering the list the user was shown.
      final spendable = await mixedWallet.spendableCoins(
        const AllCoinSelection(),
        coinType: UnspentCoinType.mweb,
      );
      expect(spendable.map((coin) => coin.id), [mweb.id]);
    });

    test("an explicit selection of the wrong kind yields nothing", () async {
      final spendable = await mixedWallet.spendableCoins(
        SpecificCoinSelection({mweb.id}),
        coinType: UnspentCoinType.nonMweb,
      );
      expect(spendable, isEmpty);
    });

    test("frozen still wins over a matching coin type", () async {
      await mixedWallet.setFrozen(regular.id, true);

      final spendable = await mixedWallet.spendableCoins(
        const AllCoinSelection(),
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

  group("notes", () {
    test("round-trip through the wallet", () async {
      await wallet.saveNote(a.id, "cold storage");
      expect((await wallet.notes())[a.id], "cold storage");
    });

    test("are scoped to the wallet", () async {
      final notesStore = FakeCoinNotesStore();
      final other = _FakeWallet(
        id: "wallet-b",
        unspents: [a],
        frozenCoinsStore: store,
        coinNotesStore: notesStore,
      );
      final mine = _FakeWallet(
        id: "wallet-a",
        unspents: [a],
        frozenCoinsStore: store,
        coinNotesStore: notesStore,
      );

      await other.saveNote(a.id, "other wallet");

      expect(await mine.notes(), isEmpty);
    });

    test("freezing an output does not touch its note", () async {
      await wallet.saveNote(a.id, "cold storage");
      await wallet.setFrozen(a.id, true);
      await wallet.setFrozen(a.id, false);

      expect((await wallet.notes())[a.id], "cold storage");
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
