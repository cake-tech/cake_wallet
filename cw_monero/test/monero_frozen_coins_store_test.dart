import "dart:io";

import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_monero/monero_frozen_coins_store.dart";
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

/// Stands in for the wallet2 freeze api, which no unit test can call: it needs
/// a loaded wallet behind the FFI. Records what actually reached it, in the
/// order it completed.
class _FakeWallet2 {
  final List<String> calls = [];

  /// Holds each call open, so a caller that does not await can be caught.
  Duration delay = Duration.zero;

  bool fail = false;

  Future<void> freeze(int index) => _apply("freeze:$index");

  Future<void> thaw(int index) => _apply("thaw:$index");

  Future<void> _apply(String call) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (fail) {
      throw Exception("wallet2 is busy");
    }
    calls.add(call);
  }
}

void main() {
  const wallet = "monero_test";
  final dataRoot = Directory("./test/data/monero_frozen_coins_store");

  late MoneroFrozenCoinsStore store;
  late _FakeWallet2 wallet2;

  /// Reads the database directly, to prove what did and did not reach it.
  /// Named to avoid shadowing the `db` global from sqlite.dart.
  final sqlite = FrozenCoinsStore();
  final notes = CoinNotesStore();

  /// Mimics the walk MoneroWallet.updateUnspent does over wallet2's coin list.
  void walk(Map<String, bool> frozenByKeyImage) {
    store.beginRefresh();
    var index = 0;
    frozenByKeyImage.forEach((keyImage, frozen) {
      store.record(keyImage: keyImage, index: index++, frozen: frozen);
    });
  }

  setUpAll(() async {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);

    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();
  });

  tearDownAll(() async {
    await db?.close();
    db = null;
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    wallet2 = _FakeWallet2();
    store = MoneroFrozenCoinsStore(freeze: wallet2.freeze, thaw: wallet2.thaw);
    await sqlite.deleteWallet(wallet);
    await notes.deleteWallet(wallet);
  });

  group("frozen state comes from wallet2, not the database", () {
    test("nothing is frozen before the coin list has been walked", () async {
      expect(await store.frozenIds(wallet), isEmpty);
    });

    test("adopts whatever wallet2 reported during the walk", () async {
      walk({"ki-a": true, "ki-b": false, "ki-c": true});

      expect(await store.frozenIds(wallet), {"ki-a", "ki-c"});
    });

    test("a refresh replaces the previous flags rather than merging", () async {
      walk({"ki-a": true, "ki-b": false});
      walk({"ki-a": false, "ki-b": true});

      expect(await store.frozenIds(wallet), {"ki-b"});
    });

    test("a coin that disappears from the walk stops being reported", () async {
      walk({"ki-a": true, "ki-b": true});
      walk({"ki-b": true});

      expect(await store.frozenIds(wallet), {"ki-b"});
    });

    test("freezing is never written to the database", () async {
      walk({"ki-a": false});
      await store.setFrozen(wallet, "ki-a", true);

      // wallet2 owns this, so a row here would be a second source of truth for
      // something the wallet already persists.
      expect(await sqlite.frozenIds(wallet), isEmpty);

      final rows = await db!.query(
        FrozenCoinsStore.tableName,
        where: "walletId = ?",
        whereArgs: [wallet],
      );
      expect(rows, isEmpty);
    });
  });

  group("changes reach wallet2", () {
    test("freezing calls freeze with the index from the walk", () async {
      walk({"ki-a": false, "ki-b": false});
      await store.setFrozen(wallet, "ki-b", true);

      expect(wallet2.calls, ["freeze:1"]);
      expect(await store.frozenIds(wallet), {"ki-b"});
    });

    test("thawing calls thaw and clears the cached flag", () async {
      walk({"ki-a": true});
      await store.setFrozen(wallet, "ki-a", false);

      expect(wallet2.calls, ["thaw:0"]);
      expect(await store.frozenIds(wallet), isEmpty);
    });

    test("the cache is not updated until wallet2 has taken the change", () async {
      walk({"ki-a": false});
      wallet2.delay = const Duration(milliseconds: 30);

      final pending = store.setFrozen(wallet, "ki-a", true);
      await Future<void>.delayed(Duration.zero);

      // The call is awaited, so nothing observes the new flag while it is still
      // in flight -- the cache cannot get ahead of the wallet.
      expect(await store.frozenIds(wallet), isEmpty);

      await pending;
      expect(await store.frozenIds(wallet), {"ki-a"});
    });

    test("successive changes reach wallet2 in the order they were made", () async {
      walk({"ki-a": false, "ki-b": false});
      wallet2.delay = const Duration(milliseconds: 10);

      await store.setFrozen(wallet, "ki-a", true);
      await store.setFrozen(wallet, "ki-b", true);
      await store.setFrozen(wallet, "ki-a", false);

      // Each caller waits, so an index cannot be acted on after the walk that
      // produced it has been replaced by a later refresh.
      expect(wallet2.calls, ["freeze:0", "freeze:1", "thaw:0"]);
      expect(await store.frozenIds(wallet), {"ki-b"});
    });

    test("a failure reaches the caller and leaves the cache alone", () async {
      walk({"ki-a": false});
      wallet2.fail = true;

      // The Bloc turns this into a visible failure. Swallowing it would leave
      // the switch showing a freeze the wallet never took.
      await expectLater(store.setFrozen(wallet, "ki-a", true), throwsException);
      expect(await store.frozenIds(wallet), isEmpty);
    });

    test("a failed thaw leaves the coin frozen, as wallet2 still has it", () async {
      walk({"ki-a": true});
      wallet2.fail = true;

      await expectLater(store.setFrozen(wallet, "ki-a", false), throwsException);
      expect(await store.frozenIds(wallet), {"ki-a"});
    });

    test("a coin absent from the last walk caches its flag and calls nothing", () async {
      // No index to act on, so wallet2 cannot be told -- but reads must still
      // reflect what the user asked for until the next refresh.
      await store.setFrozen(wallet, "ki-unknown", true);

      expect(wallet2.calls, isEmpty);
      expect(await store.frozenIds(wallet), {"ki-unknown"});
    });
  });

  group("notes are not this store's business", () {
    test("the shared notes store handles them, untouched by a walk", () async {
      await notes.save(wallet, "ki-a", "rent");

      walk({"ki-a": true});
      await store.setFrozen(wallet, "ki-a", false);

      // Nothing in the Monero override reads or writes a note, so there is no
      // Monero-specific note path that could diverge from the other chains'.
      expect((await notes.forWallet(wallet))["ki-a"], "rent");
    });
  });

  group("deleteWallet", () {
    test("clears the cache", () async {
      walk({"ki-a": true});

      await store.deleteWallet(wallet);

      expect(await store.frozenIds(wallet), isEmpty);
    });
  });
}
