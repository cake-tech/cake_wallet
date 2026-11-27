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

  late _Wallet btc;
  late _Wallet ltc;
  late _Wallet xmr;
  late _Wallet dcr;

  String legacyWalletId(String name, WalletType type) =>
      "${walletTypeToString(type).toLowerCase()}_$name";

  Future<_Wallet> insertWalletInfoRow(String name, WalletType type) async {
    final internalId = await db!.insert("WalletInfo", {
      "id": legacyWalletId(name, type),
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

    return _Wallet(legacyWalletId(name, type), internalId);
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

    btc = await insertWalletInfoRow("btc", WalletType.bitcoin);
    ltc = await insertWalletInfoRow("ltc", WalletType.litecoin);
    xmr = await insertWalletInfoRow("xmr", WalletType.monero);
    dcr = await insertWalletInfoRow("dcr", WalletType.decred);
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

    for (final id in [btc.internalId, ltc.internalId, xmr.internalId, dcr.internalId, _deletedId]) {
      await frozen.deleteWallet(id);
      await notes.deleteWallet(id);
    }
  });

  group("unspent coins info migration", () {
    test("a frozen bitcoin output keeps its freeze, keyed by hash and index", () async {
      await migrate([record(walletId: btc.id, hash: "aabb", vout: 2, isFrozen: true)]);

      expect(await frozen.frozenIds(btc.internalId), {"aabb:2"});
    });

    test("a note is carried over", () async {
      await migrate([record(walletId: btc.id, hash: "aabb", note: "rent")]);

      expect((await notes.forWallet(btc.internalId))["aabb:0"], "rent");
    });

    test("a record carrying both keeps both", () async {
      await migrate([record(walletId: btc.id, hash: "aabb", isFrozen: true, note: "cold")]);

      expect(await frozen.frozenIds(btc.internalId), {"aabb:0"});
      expect((await notes.forWallet(btc.internalId))["aabb:0"], "cold");
    });

    test("an untouched output gets a row holding the default", () async {
      // The legacy box mirrored the whole output list, so most of its records
      // said nothing. Each still becomes a row, which reads identically to an
      // absent one -- so the outcome is right, and the cost is one row per
      // output the wallet had ever seen rather than one per output the user
      // touched.
      await migrate([
        record(walletId: btc.id, hash: "aa"),
        record(walletId: btc.id, hash: "bb", vout: 1),
        record(walletId: btc.id, hash: "cc", isFrozen: true),
      ]);

      expect(await frozen.frozenIds(btc.internalId), {"cc:0"});
      expect(await notes.forWallet(btc.internalId), isEmpty, reason: "an empty note is not stored");

      final rows = await db!.query(
        FrozenCoinsStore.tableName,
        where: "walletInfoId = ?",
        whereArgs: [btc.internalId],
      );
      expect(rows, hasLength(3));
      expect(rows.where((row) => row["frozen"] == 1), hasLength(1));
    });

    test("an unselected output does not become a frozen one", () async {
      // isSending was the selection, which is not durable state. Treating it as
      // frozen would silently freeze outputs the user had merely unticked.
      await migrate([record(walletId: btc.id, hash: "aabb", isSending: false)]);

      expect(await frozen.frozenIds(btc.internalId), isEmpty);
      expect(await notes.forWallet(btc.internalId), isEmpty);
    });

    test("a Monero output keeps its note but not its freeze", () async {
      // wallet2 persists the freeze itself, so a row here would be a second
      // source of truth for it. The note has no equivalent in the wallet file.
      await migrate([
        record(
          walletId: xmr.id,
          hash: "xmrhash",
          isFrozen: true,
          note: "savings",
          keyImage: "ki-1",
        ),
      ]);

      expect(await frozen.frozenIds(xmr.internalId), isEmpty);
      expect((await notes.forWallet(xmr.internalId))["ki-1"], "savings",
          reason: "Monero outputs are keyed by key image");
    });

    test("a frozen-only Monero output produces nothing", () async {
      await migrate([record(walletId: xmr.id, hash: "h", isFrozen: true, keyImage: "ki-2")]);

      expect(await frozen.frozenIds(xmr.internalId), isEmpty);
      expect(await notes.forWallet(xmr.internalId), isEmpty);
    });

    test("an MWEB output is keyed by hash alone", () async {
      // Its vout is an index into the wallet's MWEB address list, which shifts
      // as that list grows, so it cannot be part of the identity.
      await migrate([
        record(
          walletId: ltc.id,
          hash: "mwebhash",
          vout: 7,
          isFrozen: true,
          address: "ltcmweb1qqf${"0" * 90}",
        ),
      ]);

      expect(await frozen.frozenIds(ltc.internalId), {"mwebhash"});
    });

    test("a regular Litecoin output still uses hash and index", () async {
      await migrate([
        record(
          walletId: ltc.id,
          hash: "ltchash",
          vout: 3,
          isFrozen: true,
          address: "ltc1qsomeregularaddress",
        ),
      ]);

      expect(await frozen.frozenIds(ltc.internalId), {"ltchash:3"});
    });

    test("a Decred output uses hash and index, as it has no key image", () async {
      await migrate([record(walletId: dcr.id, hash: "dcrhash", vout: 1, isFrozen: true)]);

      expect(await frozen.frozenIds(dcr.internalId), {"dcrhash:1"});
    });

    test("a record for a wallet that no longer exists contributes nothing", () async {
      await migrate([record(walletId: _deletedLegacyId, hash: "aa", isFrozen: true, note: "n")]);

      final rows = await db!.query(FrozenCoinsStore.tableName);
      expect(rows.where((row) => row["walletInfoId"] == _deletedId), isEmpty);
      expect(await notes.forWallet(_deletedId), isEmpty);
      expect(await frozen.frozenIds(btc.internalId), isEmpty);
    });

    test("a stale record does not stop the ones after it", () async {
      // It is skipped rather than treated as the end of the box, so one leftover
      // from a deleted wallet cannot silently drop every later record.
      await migrate([
        record(walletId: _deletedLegacyId, hash: "stale", isFrozen: true),
        record(walletId: btc.id, hash: "mine", isFrozen: true, note: "kept"),
      ]);

      expect(await frozen.frozenIds(btc.internalId), {"mine:0"});
      expect((await notes.forWallet(btc.internalId))["mine:0"], "kept");
    });

    test("the same output id in two wallets stays separate", () async {
      // Two wallets restored from the same seed see the same ids, which is why
      // the wallet is part of the key in both new tables.
      await migrate([
        record(walletId: btc.id, hash: "shared", isFrozen: true),
        record(walletId: dcr.id, hash: "shared", note: "theirs"),
      ]);

      expect(await frozen.frozenIds(btc.internalId), {"shared:0"});
      expect(await frozen.frozenIds(dcr.internalId), isEmpty);
      expect(await notes.forWallet(btc.internalId), isEmpty);
      expect((await notes.forWallet(dcr.internalId))["shared:0"], "theirs");
    });

    test("a migrated record is removed from the box", () async {
      await migrate([record(walletId: btc.id, hash: "aabb", isFrozen: true, note: "n")]);

      final box = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
      expect(box.values, isEmpty);
    });

    test("a record it skipped is left in the box", () async {
      // Only what actually reached the new tables is removed. A wallet list
      // that came back short for any reason must not cost the user a freeze.
      await migrate([record(walletId: _deletedLegacyId, hash: "aa", isFrozen: true)]);

      final box = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
      expect(box.values, hasLength(1));
    });

    test("a change made after the migration is not undone by a later run", () async {
      // The reason the records are removed rather than re-read: the box still
      // says frozen, so a second pass over it would resurrect a freeze the user
      // had cleared in the app.
      await migrate([record(walletId: btc.id, hash: "aabb", isFrozen: true)]);
      expect(await frozen.frozenIds(btc.internalId), {"aabb:0"});

      await frozen.setFrozen(btc.internalId, "aabb:0", false);
      await performUnspentCoinsInfoHiveMigration();

      expect(await frozen.frozenIds(btc.internalId), isEmpty);
    });

    test("a record whose write fails is kept for the next launch", () async {
      CoinNotesStore.instance = _FailingNotesStore();
      addTearDown(() => CoinNotesStore.instance = CoinNotesStore());

      await migrate([record(walletId: btc.id, hash: "aabb", isFrozen: true, note: "n")]);

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
  Future<void> save(int walletInfoId, String id, String note) async =>
      throw Exception("database is locked");
}

/// A wallet under test, by both of the ids that matter here.
class _Wallet {
  _Wallet(this.id, this.internalId);

  /// What the legacy records carry, derived from the wallet name.
  final String id;

  /// What the new tables key on, stable across a rename.
  final int internalId;
}

/// A wallet that no longer exists, so nothing resolves it.
const _deletedLegacyId = "bitcoin_deleted";
const _deletedId = 99;
