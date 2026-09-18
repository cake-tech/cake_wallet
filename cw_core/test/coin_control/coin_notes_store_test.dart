import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/db/sqlite.dart";
import "package:flutter_test/flutter_test.dart";

import "fake_coin_control_stores.dart";
import "sqlite_test_harness.dart";

// The tables key on WalletInfo.internalId, so these stand in for two saved
// wallets and one used only by the raw-sql checks.
const walletA = 1;
const walletB = 2;
const walletDup = 3;

/// Run against both implementations so the in-memory one used in other
/// packages' tests cannot drift from the sqlite one used in the app.
void contractTests(String label, CoinNotesStore Function() build) {
  group(label, () {
    late CoinNotesStore store;

    setUp(() async {
      store = build();
      await store.deleteWallet(walletA);
      await store.deleteWallet(walletB);
    });

    test("a wallet with nothing stored has no notes", () async {
      expect(await store.forWallet(walletA), isEmpty);
    });

    test("an output that was never annotated is absent", () async {
      await store.save(walletA, "aa:0", "rent");

      expect((await store.forWallet(walletA))["bb:0"], isNull);
    });

    test("a note is written and read back", () async {
      await store.save(walletA, "aa:0", "rent");

      expect((await store.forWallet(walletA))["aa:0"], "rent");
    });

    test("saving over a note replaces it", () async {
      await store.save(walletA, "aa:0", "first");
      await store.save(walletA, "aa:0", "second");

      final all = await store.forWallet(walletA);
      expect(all["aa:0"], "second");
      expect(all, hasLength(1));
    });

    test("clearing a note keeps the record and reads as empty", () async {
      await store.save(walletA, "aa:0", "rent");
      await store.save(walletA, "aa:0", "");

      // Kept rather than deleted: an empty note and an absent one both render
      // as no note, so a write never has to decide whether to drop the row.
      expect((await store.forWallet(walletA))["aa:0"], isEmpty);
    });

    test("notes for several outputs are all returned", () async {
      await store.save(walletA, "aa:0", "one");
      await store.save(walletA, "bb:0", "two");

      expect(await store.forWallet(walletA), {"aa:0": "one", "bb:0": "two"});
    });

    test("a note is scoped to the wallet", () async {
      await store.save(walletA, "shared:0", "wallet a note");

      expect(await store.forWallet(walletB), isEmpty);
    });

    test("the same id can be annotated differently in two wallets", () async {
      await store.save(walletA, "shared:0", "mine");
      await store.save(walletB, "shared:0", "theirs");

      expect((await store.forWallet(walletA))["shared:0"], "mine");
      expect((await store.forWallet(walletB))["shared:0"], "theirs");
    });

    test("deleting a wallet leaves other wallets untouched", () async {
      await store.save(walletA, "aa:0", "mine");
      await store.save(walletB, "bb:0", "theirs");

      await store.deleteWallet(walletA);

      expect(await store.forWallet(walletA), isEmpty);
      expect((await store.forWallet(walletB))["bb:0"], "theirs");
    });

    test("a note the user typed is stored verbatim", () async {
      // Bound as a parameter, so quotes and newlines are content rather than
      // anything the database has to interpret.
      const note = "it's \"cold\" storage;\nDROP TABLE CoinNote; -- 🥶";
      await store.save(walletA, "aa:0", note);

      expect((await store.forWallet(walletA))["aa:0"], note);
      expect(await store.forWallet(walletB), isEmpty);
    });
  });
}

void main() {
  contractTests("FakeCoinNotesStore", FakeCoinNotesStore.new);

  useSqliteDatabase("coin_notes_store");

  contractTests("CoinNotesStore (sqlite)", CoinNotesStore.new);

  group("CoinNotesStore schema", () {
    test("the table exists after a fresh initDb", () async {
      final rows = await db!.query(
        "sqlite_master",
        where: "type = ? AND name = ?",
        whereArgs: ["table", CoinNotesStore.tableName],
      );
      expect(rows, hasLength(1));
    });

    test("(walletId, id) is the primary key", () async {
      final info = await db!.rawQuery("PRAGMA table_info(${CoinNotesStore.tableName})");
      final keyColumns = info
          .where((column) => (column["pk"]! as int) > 0)
          .map((column) => column["name"] as String)
          .toSet();
      expect(keyColumns, {"walletInfoId", "id"});
    });

    test("it carries no frozen column, so freezing cannot be written here", () async {
      // Monero's frozen state never reaches the database, and no chain's frozen
      // state reaches this table -- there is only one place to look for it.
      final info = await db!.rawQuery("PRAGMA table_info(${CoinNotesStore.tableName})");
      expect(info.map((column) => column["name"]), isNot(contains("frozen")));
    });

    test("saving the same key twice replaces rather than duplicates", () async {
      final store = CoinNotesStore();
      await store.deleteWallet(walletDup);
      await store.save(walletDup, "aa:0", "first");
      await store.save(walletDup, "aa:0", "second");

      final rows = await db!.query(
        CoinNotesStore.tableName,
        where: "walletInfoId = ?",
        whereArgs: [walletDup],
      );
      expect(rows, hasLength(1));
      expect(rows.first["note"], "second");
    });
  });
}
