import "dart:io";

import "package:cw_core/cake_hive.dart";
import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/root_dir.dart";
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

// Faking the documents dir keeps getAppDir() off the platform channel, so the
// test runs with a plain `flutter test` on any host and in CI.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

Future<void> main() async {
  final dataRoot = Directory("./test/data/unspent_coins_info_migration");

  final frozen = FrozenCoinsStore();
  final notes = CoinNotesStore();

  String walletId(String name, WalletType type) =>
      "${walletTypeToString(type).toLowerCase()}_$name";

  Future<void> insertWalletInfoRow(String name, WalletType type) async {
    await db!.insert("WalletInfo", {
      "id": walletId(name, type),
      "name": name,
      "type": type.index,
      "isRecovery": 0,
      "restoreHeight": 0,
      "timestamp": 0,
      "dirPath": "",
      "path": "",
      "address": "",
      "showIntroCakePayCard": 0,
      "walletInfoDerivationInfoId": 0,
      "isNonSeedWallet": 0,
      "sortOrder": 0,
      "receiveInfoboxDismissed": 0,
      "showCombinedBalance": 1,
    });
  }

  UnspentCoinsInfo record({
    required String walletId,
    required String hash,
    int vout = 0,
    bool isFrozen = false,
    bool isSending = true,
    String note = "",
    String address = "addr",
    String? keyImage,
  }) =>
      UnspentCoinsInfo(
        walletId: walletId,
        hash: hash,
        isFrozen: isFrozen,
        isSending: isSending,
        noteRaw: note,
        address: address,
        vout: vout,
        value: 1000,
        keyImage: keyImage,
      );

  /// Fills the legacy box and runs the migration over it, as startup does.
  Future<void> migrate(List<UnspentCoinsInfo> records) async {
    final box = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
    await box.addAll(records);
    await box.close();

    await performUnspentCoinsInfoHiveMigration();
  }

  setUpAll(() async {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);

    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);

    // On linux getAppDir() appends /cake_wallet to the documents dir and picks the
    // first existing candidate, so create it up front to keep CI on the faked path.
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();

    // Everything must share the dir initDb resolved so boxExists finds the box.
    final appDir = await getAppDir();
    CakeHive.init(appDir.path);

    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }

    await insertWalletInfoRow("btc", WalletType.bitcoin);
    await insertWalletInfoRow("ltc", WalletType.litecoin);
    await insertWalletInfoRow("xmr", WalletType.monero);
    await insertWalletInfoRow("dcr", WalletType.decred);
  });

  tearDownAll(() async {
    await db?.close();
    db = null;
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    // The migration removes what it migrated, but a record it deliberately
    // skipped stays, so the box is emptied here to keep the tests isolated.
    await CakeHive.deleteBoxFromDisk(UnspentCoinsInfo.boxName);

    for (final id in [
      walletId("btc", WalletType.bitcoin),
      walletId("ltc", WalletType.litecoin),
      walletId("xmr", WalletType.monero),
      walletId("dcr", WalletType.decred),
      "bitcoin_deleted",
    ]) {
      await frozen.deleteWallet(id);
      await notes.deleteWallet(id);
    }
  });

  group("unspent coins info migration", () {
    test("a frozen bitcoin output keeps its freeze, keyed by hash and index", () async {
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([record(walletId: btc, hash: "aabb", vout: 2, isFrozen: true)]);

      expect(await frozen.frozenIds(btc), {"aabb:2"});
    });

    test("a note is carried over", () async {
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([record(walletId: btc, hash: "aabb", note: "rent")]);

      expect((await notes.forWallet(btc))["aabb:0"], "rent");
    });

    test("a record carrying both keeps both", () async {
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([record(walletId: btc, hash: "aabb", isFrozen: true, note: "cold")]);

      expect(await frozen.frozenIds(btc), {"aabb:0"});
      expect((await notes.forWallet(btc))["aabb:0"], "cold");
    });

    test("an untouched output gets a row holding the default", () async {
      // The legacy box mirrored the whole output list, so most of its records
      // said nothing. Each still becomes a row, which reads identically to an
      // absent one -- so the outcome is right, and the cost is one row per
      // output the wallet had ever seen rather than one per output the user
      // touched.
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([
        record(walletId: btc, hash: "aa"),
        record(walletId: btc, hash: "bb", vout: 1),
        record(walletId: btc, hash: "cc", isFrozen: true),
      ]);

      expect(await frozen.frozenIds(btc), {"cc:0"});
      expect(await notes.forWallet(btc), isEmpty, reason: "an empty note is not stored");

      final rows = await db!.query(
        FrozenCoinsStore.tableName,
        where: "walletId = ?",
        whereArgs: [btc],
      );
      expect(rows, hasLength(3));
      expect(rows.where((row) => row["frozen"] == 1), hasLength(1));
    });

    test("an unselected output does not become a frozen one", () async {
      // isSending was the selection, which is not durable state. Treating it as
      // frozen would silently freeze outputs the user had merely unticked.
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([record(walletId: btc, hash: "aabb", isSending: false)]);

      expect(await frozen.frozenIds(btc), isEmpty);
      expect(await notes.forWallet(btc), isEmpty);
    });

    test("a Monero output keeps its note but not its freeze", () async {
      // wallet2 persists the freeze itself, so a row here would be a second
      // source of truth for it. The note has no equivalent in the wallet file.
      final xmr = walletId("xmr", WalletType.monero);
      await migrate([
        record(
          walletId: xmr,
          hash: "xmrhash",
          isFrozen: true,
          note: "savings",
          keyImage: "ki-1",
        ),
      ]);

      expect(await frozen.frozenIds(xmr), isEmpty);
      expect((await notes.forWallet(xmr))["ki-1"], "savings",
          reason: "Monero outputs are keyed by key image");
    });

    test("a frozen-only Monero output produces nothing", () async {
      final xmr = walletId("xmr", WalletType.monero);
      await migrate([record(walletId: xmr, hash: "h", isFrozen: true, keyImage: "ki-2")]);

      expect(await frozen.frozenIds(xmr), isEmpty);
      expect(await notes.forWallet(xmr), isEmpty);
    });

    test("an MWEB output is keyed by hash alone", () async {
      // Its vout is an index into the wallet's MWEB address list, which shifts
      // as that list grows, so it cannot be part of the identity.
      final ltc = walletId("ltc", WalletType.litecoin);
      await migrate([
        record(
          walletId: ltc,
          hash: "mwebhash",
          vout: 7,
          isFrozen: true,
          address: "ltcmweb1qqf${"0" * 90}",
        ),
      ]);

      expect(await frozen.frozenIds(ltc), {"mwebhash"});
    });

    test("a regular Litecoin output still uses hash and index", () async {
      final ltc = walletId("ltc", WalletType.litecoin);
      await migrate([
        record(
          walletId: ltc,
          hash: "ltchash",
          vout: 3,
          isFrozen: true,
          address: "ltc1qsomeregularaddress",
        ),
      ]);

      expect(await frozen.frozenIds(ltc), {"ltchash:3"});
    });

    test("a Decred output uses hash and index, as it has no key image", () async {
      final dcr = walletId("dcr", WalletType.decred);
      await migrate([record(walletId: dcr, hash: "dcrhash", vout: 1, isFrozen: true)]);

      expect(await frozen.frozenIds(dcr), {"dcrhash:1"});
    });

    test("a record for a wallet that no longer exists contributes nothing", () async {
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([record(walletId: "bitcoin_deleted", hash: "aa", isFrozen: true, note: "n")]);

      final rows = await db!.query(FrozenCoinsStore.tableName);
      expect(rows.where((row) => row["walletId"] == "bitcoin_deleted"), isEmpty);
      expect(await notes.forWallet("bitcoin_deleted"), isEmpty);
      expect(await frozen.frozenIds(btc), isEmpty);
    });

    test("a stale record does not stop the ones after it", () async {
      // It is skipped rather than treated as the end of the box, so one leftover
      // from a deleted wallet cannot silently drop every later record.
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([
        record(walletId: "bitcoin_deleted", hash: "stale", isFrozen: true),
        record(walletId: btc, hash: "mine", isFrozen: true, note: "kept"),
      ]);

      expect(await frozen.frozenIds(btc), {"mine:0"});
      expect((await notes.forWallet(btc))["mine:0"], "kept");
    });

    test("the same output id in two wallets stays separate", () async {
      // Two wallets restored from the same seed see the same ids, which is why
      // the wallet is part of the key in both new tables.
      final btc = walletId("btc", WalletType.bitcoin);
      final dcr = walletId("dcr", WalletType.decred);
      await migrate([
        record(walletId: btc, hash: "shared", isFrozen: true),
        record(walletId: dcr, hash: "shared", note: "theirs"),
      ]);

      expect(await frozen.frozenIds(btc), {"shared:0"});
      expect(await frozen.frozenIds(dcr), isEmpty);
      expect(await notes.forWallet(btc), isEmpty);
      expect((await notes.forWallet(dcr))["shared:0"], "theirs");
    });

    test("a migrated record is removed from the box", () async {
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([record(walletId: btc, hash: "aabb", isFrozen: true, note: "n")]);

      final box = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
      expect(box.values, isEmpty);
    });

    test("a record it skipped is left in the box", () async {
      // Only what actually reached the new tables is removed. A wallet list
      // that came back short for any reason must not cost the user a freeze.
      await migrate([record(walletId: "bitcoin_deleted", hash: "aa", isFrozen: true)]);

      final box = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
      expect(box.values, hasLength(1));
    });

    test("a change made after the migration is not undone by a later run", () async {
      // The reason the records are removed rather than re-read: the box still
      // says frozen, so a second pass over it would resurrect a freeze the user
      // had cleared in the app.
      final btc = walletId("btc", WalletType.bitcoin);
      await migrate([record(walletId: btc, hash: "aabb", isFrozen: true)]);
      expect(await frozen.frozenIds(btc), {"aabb:0"});

      await frozen.setFrozen(btc, "aabb:0", false);
      await performUnspentCoinsInfoHiveMigration();

      expect(await frozen.frozenIds(btc), isEmpty);
    });

    test("a record whose write fails is kept for the next launch", () async {
      final btc = walletId("btc", WalletType.bitcoin);
      CoinNotesStore.instance = _FailingNotesStore();
      addTearDown(() => CoinNotesStore.instance = CoinNotesStore());

      await migrate([record(walletId: btc, hash: "aabb", isFrozen: true, note: "n")]);

      final box = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
      expect(box.values, hasLength(1), reason: "still there to retry");
    });

    test("with no legacy box there is nothing to do and nothing throws", () async {
      await CakeHive.deleteBoxFromDisk(UnspentCoinsInfo.boxName);
      expect(await CakeHive.boxExists(UnspentCoinsInfo.boxName), isFalse);

      await performUnspentCoinsInfoHiveMigration();

      expect(await db!.query(FrozenCoinsStore.tableName), isEmpty);
      expect(await db!.query(CoinNotesStore.tableName), isEmpty);
    });
  });
}

/// Fails every note write, to prove a record is only dropped once it landed.
class _FailingNotesStore extends CoinNotesStore {
  @override
  Future<void> save(String walletId, String id, String note) async =>
      throw Exception("database is locked");
}
