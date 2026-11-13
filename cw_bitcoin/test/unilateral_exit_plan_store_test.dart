import "package:cw_bitcoin/lightning/unilateral_exit_plan_store.dart";
import "package:cw_core/db/sqlite.dart" as app_db;
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    app_db.db = await openDatabase(inMemoryDatabasePath);
  });

  tearDown(() async {
    await app_db.db!.close();
    app_db.db = null;
  });

  test("reads nothing before an exit is written", () async {
    expect(await const UnilateralExitPlanStore(walletId: "wallet-1").readAll(), isEmpty);
  });

  test("keeps every exit of a wallet, not just the latest", () async {
    const store = UnilateralExitPlanStore(walletId: "wallet-1");

    await store.write("sweep-a", "first");
    await store.write("sweep-b", "second");

    expect(await store.readAll(), unorderedEquals(["first", "second"]));
  });

  test("rewriting an exit replaces it rather than adding a row", () async {
    const store = UnilateralExitPlanStore(walletId: "wallet-1");

    await store.write("sweep-a", '{"status":"active"}');
    await store.write("sweep-a", '{"status":"complete"}');

    expect(await store.readAll(), ['{"status":"complete"}']);
  });

  test("exits are kept per wallet", () async {
    await const UnilateralExitPlanStore(walletId: "wallet-1").write("sweep-a", "first");
    await const UnilateralExitPlanStore(walletId: "wallet-2").write("sweep-b", "second");

    expect(await const UnilateralExitPlanStore(walletId: "wallet-1").readAll(), ["first"]);
    expect(await const UnilateralExitPlanStore(walletId: "wallet-2").readAll(), ["second"]);
  });

  test("delete removes only that exit", () async {
    const store = UnilateralExitPlanStore(walletId: "wallet-1");

    await store.write("sweep-a", "first");
    await store.write("sweep-b", "second");
    await store.delete("sweep-a");

    expect(await store.readAll(), ["second"]);
  });
}
