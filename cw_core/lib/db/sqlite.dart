
import 'package:sqflite/sqflite.dart';

late Database db; 

Future<void> initDb({String? pathOverride}) async {
  db = await openDatabase(
    pathOverride ?? "cake.db",
    version: 1,
    onCreate: (Database db, int version) async {
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