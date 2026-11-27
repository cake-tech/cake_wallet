import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/db/sqlite.dart";
import "package:flutter_test/flutter_test.dart";

import "fake_coin_control_stores.dart";
import "sqlite_test_harness.dart";

// The tables key on WalletInfo.internalId, so these stand in for two saved
// wallets and one used only by the raw-sql checks.
const walletA = 1;
const walletB = 2;
const walletDup = 3;

/// Every behaviour the wallet mixin and the coin control Bloc rely on, run
/// against both implementations so the in-memory one used in other packages'
/// tests cannot drift from the sqlite one used in the app.
void contractTests(String label, FrozenCoinsStore Function() build) {
  group(label, () {
    late FrozenCoinsStore store;

    setUp(() async {
      store = build();
      await store.deleteWallet(walletA);
      await store.deleteWallet(walletB);
    });

    test("a wallet with nothing stored has no frozen ids", () async {
      expect(await store.frozenIds(walletA), isEmpty);
    });

    test("freezing then reading back", () async {
      await store.setFrozen(walletA, "aa:0", true);

      expect(await store.frozenIds(walletA), {"aa:0"});
    });

    test("freezing the same output twice does not report it twice", () async {
      await store.setFrozen(walletA, "aa:0", true);
      await store.setFrozen(walletA, "aa:0", true);

      expect(await store.frozenIds(walletA), {"aa:0"});
    });

    test("thawing clears the flag", () async {
      await store.setFrozen(walletA, "aa:0", true);
      await store.setFrozen(walletA, "aa:0", false);

      expect(await store.frozenIds(walletA), isEmpty);
    });

    test("thawing an output that was never frozen is not an error", () async {
      await store.setFrozen(walletA, "never-touched", false);

      expect(await store.frozenIds(walletA), isEmpty);
    });

    test("re-freezing after a thaw works", () async {
      await store.setFrozen(walletA, "aa:0", true);
      await store.setFrozen(walletA, "aa:0", false);
      await store.setFrozen(walletA, "aa:0", true);

      expect(await store.frozenIds(walletA), {"aa:0"});
    });

    test("only the frozen ones are reported", () async {
      await store.setFrozen(walletA, "frozen:0", true);
      await store.setFrozen(walletA, "thawed:0", false);

      expect(await store.frozenIds(walletA), {"frozen:0"});
    });

    test("a record for one wallet is invisible to another", () async {
      // Two wallets restored from the same seed see the same output ids. If the
      // wallet were not part of the key, freezing in one would freeze in both
      // and the frozen amount would be attributed twice.
      await store.setFrozen(walletA, "shared:0", true);

      expect(await store.frozenIds(walletB), isEmpty);
    });

    test("the same id can be frozen independently in two wallets", () async {
      await store.setFrozen(walletA, "shared:0", true);
      await store.setFrozen(walletB, "shared:0", false);

      expect(await store.frozenIds(walletA), {"shared:0"});
      expect(await store.frozenIds(walletB), isEmpty);
    });

    test("deleting a wallet leaves other wallets untouched", () async {
      await store.setFrozen(walletA, "aa:0", true);
      await store.setFrozen(walletB, "bb:0", true);

      await store.deleteWallet(walletA);

      expect(await store.frozenIds(walletA), isEmpty);
      expect(await store.frozenIds(walletB), {"bb:0"});
    });

    test("a Monero-style key image id round-trips", () async {
      const keyImage = "9a1f0c3b7e5d2a48f6b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f60718293a4b5c";
      await store.setFrozen(walletA, keyImage, true);

      expect(await store.frozenIds(walletA), {keyImage});
    });
  });
}

void main() {
  contractTests("FakeFrozenCoinsStore", FakeFrozenCoinsStore.new);

  group("FakeFrozenCoinsStore bookkeeping", () {
    test("holds no records until the user freezes, then keeps one per output", () async {
      final store = FakeFrozenCoinsStore();
      expect(store.recordCount, 0);

      await store.setFrozen(walletA, "aa:0", true);
      expect(store.recordCount, 1);

      // Kept, not dropped: the record now holds the default.
      await store.setFrozen(walletA, "aa:0", false);
      expect(store.recordCount, 1);

      await store.setFrozen(walletA, "bb:0", true);
      expect(store.recordCount, 2);
    });
  });

  // The sqlite store is exercised against a real database so the composite key
  // is proven in SQL, not just in the Dart fake.
  useSqliteDatabase("frozen_coins_store");

  contractTests("FrozenCoinsStore (sqlite)", FrozenCoinsStore.new);

  group("FrozenCoinsStore schema", () {
    test("the table exists after a fresh initDb", () async {
      final rows = await db!.query(
        "sqlite_master",
        where: "type = ? AND name = ?",
        whereArgs: ["table", FrozenCoinsStore.tableName],
      );
      expect(rows, hasLength(1));
    });

    test("(walletId, id) is the primary key", () async {
      final info = await db!.rawQuery("PRAGMA table_info(${FrozenCoinsStore.tableName})");
      final keyColumns = info
          .where((column) => (column["pk"]! as int) > 0)
          .map((column) => column["name"] as String)
          .toSet();
      expect(keyColumns, {"walletInfoId", "id"});
    });

    test("it carries no note column, so notes cannot be written here", () async {
      final info = await db!.rawQuery("PRAGMA table_info(${FrozenCoinsStore.tableName})");
      expect(info.map((column) => column["name"]), isNot(contains("note")));
    });

    test("setting the same key twice replaces rather than duplicates", () async {
      final store = FrozenCoinsStore();
      await store.deleteWallet(walletDup);
      await store.setFrozen(walletDup, "aa:0", true);
      await store.setFrozen(walletDup, "aa:0", false);

      final rows = await db!.query(
        FrozenCoinsStore.tableName,
        where: "walletInfoId = ?",
        whereArgs: [walletDup],
      );
      expect(rows, hasLength(1), reason: "a thawed record is kept, not deleted");
      expect(rows.first["frozen"], 0);
    });
  });
}
