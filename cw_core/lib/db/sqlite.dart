
import 'dart:io';

import 'package:cw_core/root_dir.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

late Database db;


Future<void> createTablesV2(Database db) async {
  await db.execute(
      '''
CREATE TABLE WalletInfo (
	walletInfoId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	id TEXT NOT NULL,
	name TEXT NOT NULL,
	"type" INTEGER NOT NULL,
	isRecovery INTEGER DEFAULT (0) NOT NULL,
  walletInfoDerivationInfoId INTEGER NOT NULL,
	restoreHeight INTEGER DEFAULT (0) NOT NULL,
  "timestamp" INTEGER DEFAULT (0) NOT NULL,
  dirPath TEXT NOT NULL,
  "path" TEXT NOT NULL,
  address TEXT NOT NULL,
  yatEid TEXT,
  yatLastUsedAddressRaw TEXT,
  showIntroCakePayCard INTEGER DEFAULT (1),
  addressPageType TEXT,
  network TEXT,
  hardwareWalletType INTEGER,
  parentAddress TEXT,
  hashedWalletIdentifier TEXT,
  isNonSeedWallet INTEGER DEFAULT (0) NOT NULL,
  sortOrder INTEGER DEFAULT (0) NOT NULL
);
''');

  await db.execute(
      '''
CREATE TABLE WalletInfoDerivationInfo (
	walletInfoDerivationInfoId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	address TEXT NOT NULL,
	balance TEXT NOT NULL,
	transactionsCount INTEGER DEFAULT (0) NOT NULL,
	derivationType INTEGER NOT NULL,
	derivationPath TEXT,
	scriptType TEXT,
	description TEXT
);
''');

  await db.execute(
      '''
CREATE TABLE WalletInfoAddress (
	walletInfoAddressId INTEGER PRIMARY KEY AUTOINCREMENT,
	walletInfoId INTEGER,
	"type" INTEGER NOT NULL,
	address TEXT NOT NULL,
	CONSTRAINT WalletInfoAddress_WalletInfo_FK FOREIGN KEY (walletInfoId) REFERENCES WalletInfo(walletInfoId)
);
''');

  await db.execute(
      '''
CREATE TABLE WalletInfoAddressInfo (
	walletInfoAddressInfoId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	walletInfoId INTEGER NOT NULL,
	mapKey INTEGER NOT NULL,
	mapValueAccountIndex INTEGER NOT NULL,
	mapValueAddress TEXT NOT NULL,
	mapValueLabel TEXT NOT NULL,
	CONSTRAINT WalletInfoAddressInfo_WalletInfo_FK FOREIGN KEY (walletInfoId) REFERENCES WalletInfo(walletInfoId)
);
''');

  await db.execute(
      '''
CREATE TABLE "WalletInfoAddressMap" (
	walletInfoAddressMapId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	walletInfoId INTEGER NOT NULL,
	addressKey TEXT NOT NULL,
	addressValue TEXT NOT NULL,
	CONSTRAINT WalletInfoAddress_WalletInfo_FK FOREIGN KEY (walletInfoId) REFERENCES WalletInfo(walletInfoId)
);
        '''
  );
}

Future<void> createTablesV3(Database db) async {
  db.execute("""
CREATE TABLE Node (
NodeId INTEGER PRIMARY KEY,
uri TEXT NOT NULL,
path TEXT,
login TEXT,
password TEXT,
isPow INTEGER NOT NULL,
useSSL INTEGER,
typeRaw INTEGER NOT NULL,
trusted INTEGER NOT NULL,
socksProxyAddress TEXT,
isEnabledForAutoSwitching INTEGER NOT NULL
);
        """);
}

Future<void> initDb({String? pathOverride}) async {
  if (Platform.isLinux || Platform.isWindows) {
    databaseFactory = databaseFactoryFfi;
  }

  // getAppDir is predictable on all platforms and ensures the db gets included in backups.
  final dbFileOld = File("${await getDatabasesPath()}/cake.db");
  final dbFile = File("${(await getAppDir()).path}/cake.db");

  if (Platform.isAndroid && dbFileOld.existsSync() && dbFileOld.path != dbFile.path) {
    final copied = dbFileOld.copySync(dbFile.path);
    if (copied.existsSync()) {
      dbFileOld.deleteSync();
    }
  }

  db = await openDatabase(dbFile.path, version: 3,
    onCreate: (Database db, int version) async {
     await createTablesV2(db);
     await createTablesV3(db);
    },
    onUpgrade: (Database db, int oldVersion, int newVersion) async{
      if(oldVersion < 3 && newVersion >= 3) {
        await createTablesV3(db);
      }

    }
  );
}

Future<Map<String, dynamic>> dumpDb() async {
  try {
    return await _dumpDb();
  } catch (e) {
    return {
      "error": e.toString(),
      "stackTrace": StackTrace.current.toString(),
    };
  }
}

Future<List<String>> _getTableNames() async {
  final tableNames = await db.rawQuery('SELECT name FROM sqlite_master WHERE type = "table"');
  return tableNames.map((e) => (e["name"]).toString()).toList();
}

Future<Map<String, dynamic>> _dumpDb() async {
  final tableNames = await _getTableNames();
  final ret = <String, dynamic>{};
  for (final tableName in tableNames) {
    ret[tableName] = await db.query(tableName);
  }
  return ret;
}
