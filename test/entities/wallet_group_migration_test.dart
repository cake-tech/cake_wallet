import "dart:io";

import "package:cw_core/wallet_group_db_entry.dart";
import "package:cake_wallet/entities/wallet_group_migration.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:shared_preferences/shared_preferences.dart";
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

var _clock = DateTime(2024);

/// Inserts a wallet row the way main left it: no groupId, optional legacy hash.
Future<WalletInfo> _wallet(
  String name,
  WalletType type, {
  String? hash,
  DerivationType derivationType = DerivationType.unknown,
  HardwareWalletType? hardwareWalletType,
}) async {
  _clock = _clock.add(const Duration(minutes: 1));
  final derivationId = await DerivationInfo(derivationType: derivationType).save();
  final wallet = WalletInfo.external(
    id: "id_$name",
    name: name,
    type: type,
    isRecovery: false,
    restoreHeight: 0,
    date: _clock,
    dirPath: "",
    path: "",
    address: "addr_$name",
    derivationInfoId: derivationId,
    hashedWalletIdentifier: hash,
    hardwareWalletType: hardwareWalletType,
  );
  await wallet.save();
  return wallet;
}

Future<Map<String, WalletInfo>> _walletsByName() async =>
    {for (final w in await WalletInfo.getAll()) w.name: w};

Future<void> main() async {
  final dataRoot = Directory("./test/data/wallet_group_migration");

  setUpAll(() async {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);

    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();
  });

  setUp(() async {
    await db!.delete(WalletInfo.tableName);
    await db!.delete(DerivationInfo.tableName);
    await db!.delete(WalletGroupDbEntry.tableName);
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await db?.close();
    db = null;
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  test("clean BTC+ETH+SOL group keeps its custom name, clears hash and pref", () async {
    SharedPreferences.setMockInitialValues({"wallet_group_name_seedA": "My Group"});
    final prefs = await SharedPreferences.getInstance();

    await _wallet("btc", WalletType.bitcoin,
        hash: "seedA", derivationType: DerivationType.bip39);
    await _wallet("eth", WalletType.ethereum, hash: "seedA");
    await _wallet("sol", WalletType.solana, hash: "seedA");

    await migrateLegacyWalletsToGroups(prefs);

    final groups = await WalletGroupDbEntry.getAll();
    expect(groups.length, 1);
    expect(groups.single.name, "My Group");

    final wallets = (await _walletsByName()).values;
    expect(wallets.map((w) => w.groupId).toSet(), {groups.single.id});
    expect(wallets.map((w) => w.hashedWalletIdentifier).toSet(), {null});
    expect(prefs.containsKey("wallet_group_name_seedA"), isFalse);
  });

  test("a second restored BTC splits off; the oldest BTC stays with ETH", () async {
    final prefs = await SharedPreferences.getInstance();

    await _wallet("btc old", WalletType.bitcoin,
        hash: "seedA", derivationType: DerivationType.bip39);
    await _wallet("eth", WalletType.ethereum, hash: "seedA");
    await _wallet("btc new", WalletType.bitcoin,
        hash: "seedA", derivationType: DerivationType.bip39);

    await migrateLegacyWalletsToGroups(prefs);

    final w = await _walletsByName();
    expect(w["btc old"]!.groupId, w["eth"]!.groupId);
    expect(w["btc new"]!.groupId, isNot(w["eth"]!.groupId));
    expect((await WalletGroupDbEntry.getAll()).length, 2);
    expect((await WalletGroupDbEntry.get(w["btc new"]!.groupId!))!.name, "btc new");
  });

  test("BTC + Decred with unknown derivation stay together (picker rule)", () async {
    final prefs = await SharedPreferences.getInstance();

    await _wallet("btc", WalletType.bitcoin,
        hash: "seedA", derivationType: DerivationType.bip39);
    await _wallet("dcr", WalletType.decred, hash: "seedA");

    await migrateLegacyWalletsToGroups(prefs);

    final w = await _walletsByName();
    expect(w["btc"]!.groupId, isNotNull);
    expect(w["btc"]!.groupId, w["dcr"]!.groupId);
    expect((await WalletGroupDbEntry.getAll()).length, 1);
  });

  test("only the hardware wallet splits off a seed group", () async {
    final prefs = await SharedPreferences.getInstance();

    await _wallet("btc", WalletType.bitcoin,
        hash: "seedA", derivationType: DerivationType.bip39);
    await _wallet("eth", WalletType.ethereum, hash: "seedA");
    await _wallet("sol hw", WalletType.solana,
        hash: "seedA", hardwareWalletType: HardwareWalletType.ledger);

    await migrateLegacyWalletsToGroups(prefs);

    final w = await _walletsByName();
    expect(w["btc"]!.groupId, w["eth"]!.groupId);
    expect(w["sol hw"]!.groupId, isNotNull);
    expect(w["sol hw"]!.groupId, isNot(w["eth"]!.groupId));
    expect((await WalletGroupDbEntry.getAll()).length, 2);
  });

  test("running twice changes nothing the second time", () async {
    final prefs = await SharedPreferences.getInstance();

    await _wallet("btc", WalletType.bitcoin,
        hash: "seedA", derivationType: DerivationType.bip39);
    await _wallet("eth", WalletType.ethereum, hash: "seedA");
    await _wallet("xmr", WalletType.monero, hash: "seedB");

    await migrateLegacyWalletsToGroups(prefs);
    final groupsBefore = await db!.query(WalletGroupDbEntry.tableName, orderBy: "id");
    final walletsBefore = await db!.query(WalletInfo.tableName, orderBy: "id");

    await migrateLegacyWalletsToGroups(prefs);

    expect(await db!.query(WalletGroupDbEntry.tableName, orderBy: "id"), groupsBefore);
    expect(await db!.query(WalletInfo.tableName, orderBy: "id"), walletsBefore);
  });

  test("a failure inside a group's transaction writes nothing of that group", () async {
    SharedPreferences.setMockInitialValues({"wallet_group_name_seedA": "My Group"});
    final prefs = await SharedPreferences.getInstance();

    await _wallet("btc", WalletType.bitcoin,
        hash: "seedA", derivationType: DerivationType.bip39);
    await _wallet("eth", WalletType.ethereum, hash: "seedA");
    await _wallet("xmr", WalletType.monero, hash: "seedB");

    await migrateLegacyWalletsToGroups(
      prefs,
      beforeGroupCommit: (wallets) {
        if (wallets.length > 1) throw StateError("boom");
      },
    );

    var w = await _walletsByName();
    expect(w["btc"]!.groupId, isNull);
    expect(w["eth"]!.groupId, isNull);
    expect(w["btc"]!.hashedWalletIdentifier, "seedA");
    expect(w["eth"]!.hashedWalletIdentifier, "seedA");
    expect(prefs.getString("wallet_group_name_seedA"), "My Group");

    // The other group still committed.
    expect(w["xmr"]!.groupId, isNotNull);
    expect(w["xmr"]!.hashedWalletIdentifier, isNull);
    expect((await WalletGroupDbEntry.getAll()).map((g) => g.id), [w["xmr"]!.groupId]);

    // The next run picks the failed group up again.
    await migrateLegacyWalletsToGroups(prefs);
    w = await _walletsByName();
    expect(w["btc"]!.groupId, isNotNull);
    expect(w["btc"]!.groupId, w["eth"]!.groupId);
    expect((await WalletGroupDbEntry.get(w["btc"]!.groupId!))!.name, "My Group");
    expect(prefs.containsKey("wallet_group_name_seedA"), isFalse);
  });
}
