import "dart:io";

import "package:cw_core/db/backup_db.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => tempDir = Directory.systemTemp.createTempSync("backup_db_test"));

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<String> createCakeDb() async {
    final path = "${tempDir.path}/cake.db";
    final db = await openDatabase(path, singleInstance: false);
    await db.execute("CREATE TABLE WalletInfo (walletInfoId INTEGER PRIMARY KEY AUTOINCREMENT, "
        "id TEXT NOT NULL, name TEXT NOT NULL, walletInfoDerivationInfoId INTEGER NOT NULL)");
    await db.execute("CREATE TABLE WalletInfoDerivationInfo "
        "(walletInfoDerivationInfoId INTEGER PRIMARY KEY AUTOINCREMENT, address TEXT NOT NULL)");
    await db.execute("CREATE TABLE WalletInfoAddress (walletInfoAddressId INTEGER PRIMARY KEY, "
        "walletInfoId INTEGER, address TEXT NOT NULL)");
    await db.execute("CREATE TABLE BalanceCardStyleSettings (walletInfoId INTEGER, "
        "accountIndex INTEGER DEFAULT -1, PRIMARY KEY (walletInfoId, accountIndex))");
    await db.execute(
        "CREATE TABLE Trade (tradeId INTEGER PRIMARY KEY, id TEXT NOT NULL, walletId TEXT)");
    await db.execute("CREATE TABLE Erc20Token (Erc20TokenId INTEGER PRIMARY KEY, "
        "walletName TEXT NOT NULL, contractAddress TEXT NOT NULL)");
    await db.execute("CREATE TABLE BridgeTransfer (id TEXT PRIMARY KEY, wallet_id TEXT NOT NULL)");
    await db
        .execute("CREATE TABLE PriceData (fromCurrency TEXT, toCurrency TEXT, timestamp INTEGER, "
            "price TEXT, PRIMARY KEY (fromCurrency, toCurrency, timestamp))");
    await db.execute("CREATE TABLE Node (NodeId INTEGER PRIMARY KEY, uri TEXT NOT NULL)");

    for (final (index, id, name) in [
      (1, "kept", "Main"),
      (2, "dropped", "Savings"),
      (3, "dropped_same_name", "Main"),
    ]) {
      await db.insert("WalletInfoDerivationInfo",
          {"walletInfoDerivationInfoId": index, "address": "addr$index"});
      await db.insert("WalletInfo",
          {"walletInfoId": index, "id": id, "name": name, "walletInfoDerivationInfoId": index});
      await db.insert("WalletInfoAddress", {"walletInfoId": index, "address": "addr$index"});
      await db.insert("BalanceCardStyleSettings", {"walletInfoId": index});
      await db.insert("Trade", {"id": "trade$index", "walletId": id});
      await db.insert("Erc20Token", {"walletName": name, "contractAddress": "0x$index"});
      await db.insert("BridgeTransfer", {"id": "bridge$index", "wallet_id": name});
    }
    await db.insert(
        "PriceData", {"fromCurrency": "BTC", "toCurrency": "USD", "timestamp": 1, "price": "1"});
    await db.insert("Node", {"uri": "node.example.com"});
    await db.close();
    return path;
  }

  test("trimDatabaseCopyForBackup keeps only rows of the kept wallets", () async {
    final path = await createCakeDb();

    await trimDatabaseCopyForBackup(path, keepWalletIds: {"kept"});

    final db = await openDatabase(path, singleInstance: false);
    Future<List<Object?>> column(String table, String name) async =>
        (await db.query(table)).map((row) => row[name]).toList();

    expect(await column("WalletInfo", "id"), ["kept"]);
    expect(await column("WalletInfoDerivationInfo", "address"), ["addr1"]);
    expect(await column("WalletInfoAddress", "walletInfoId"), [1]);
    expect(await column("BalanceCardStyleSettings", "walletInfoId"), [1]);
    expect(await column("Trade", "walletId"), ["kept"]);
    expect(await column("Erc20Token", "walletName"), ["Main", "Main"]);
    expect(await column("BridgeTransfer", "wallet_id"), ["Main", "Main"]);
    expect(await db.query("PriceData"), isEmpty);
    expect(await column("Node", "uri"), ["node.example.com"]);
    await db.close();
  });

  test("pruneAccountDatabaseCopy keeps only the given accounts", () async {
    final path = "${tempDir.path}/zec.v2.db";
    final db = await openDatabase(path, singleInstance: false);
    await db
        .execute("CREATE TABLE accounts (id_account INTEGER PRIMARY KEY, name TEXT, seed TEXT)");
    await db.execute(
        "CREATE TABLE notes (id_note INTEGER PRIMARY KEY, account INTEGER, value INTEGER)");
    await db.execute("CREATE TABLE headers (height INTEGER PRIMARY KEY, hash TEXT)");
    for (final id in [1, 2, 3]) {
      await db.insert("accounts", {"id_account": id, "name": "wallet$id", "seed": "seed$id"});
      await db.insert("notes", {"account": id, "value": id * 10});
    }
    await db.insert("headers", {"height": 100, "hash": "abc"});
    await db.close();

    expect(await accountIdsByName(path), {"wallet1": 1, "wallet2": 2, "wallet3": 3});

    await pruneAccountDatabaseCopy(path, keepAccountIds: {2});

    final pruned = await openDatabase(path, singleInstance: false);
    expect((await pruned.query("accounts")).map((row) => row["seed"]), ["seed2"]);
    expect((await pruned.query("notes")).map((row) => row["account"]), [2]);
    expect(await pruned.query("headers"), hasLength(1));
    await pruned.close();
  });

  test("pruneAccountDatabaseCopy with no kept accounts empties account data", () async {
    final path = "${tempDir.path}/zec.db";
    final db = await openDatabase(path, singleInstance: false);
    await db.execute("CREATE TABLE accounts (id_account INTEGER PRIMARY KEY, seed TEXT)");
    await db.insert("accounts", {"id_account": 1, "seed": "seed1"});
    await db.close();

    await pruneAccountDatabaseCopy(path, keepAccountIds: {});

    final pruned = await openDatabase(path, singleInstance: false);
    expect(await pruned.query("accounts"), isEmpty);
    await pruned.close();
  });
}
