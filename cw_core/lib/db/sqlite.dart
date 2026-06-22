import 'dart:io';

import 'package:cw_core/db/sqlite_debug.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

Database? db;

Future<void> _addColumnIfNotExists(
  Database db, {
  required String table,
  required String column,
  required String definition,
}) async {
  final result = await db.rawQuery("PRAGMA table_info($table)");
  final columnExists = result.any((row) => row['name'] == column);

  if (!columnExists) {
    await db.execute(
      'ALTER TABLE $table ADD COLUMN $column $definition;',
    );
  }
}

Future<File> sqliteDebugMarkerFile() async {
  final appDir = await getAppDir();
  final dbDebugMarker = p.join(appDir.path, ".sqlite_db_debug");
  return File(dbDebugMarker);
}

Future<void> initDb({String? pathOverride}) async {
  if (!kDebugMode && !kProfileMode) {
    await _initDb(pathOverride: pathOverride);
    return;
  }
  final dbDebugMarker = await sqliteDebugMarkerFile();
  try {
    if (dbDebugMarker.existsSync()) {
      throw Exception("Debug marker is present");
    }
    await _initDb(pathOverride: pathOverride);
  } catch (e, s) {
    await handleSqliteError(e, s);
  }
}

Future<void> _initDb({String? pathOverride}) async {
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
  await db?.close();
  db = await openDatabase(dbFile.path, version: 9,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
    printV("migrating: $oldVersion, $newVersion");
    if (oldVersion <= 1) {
      await db.execute('''
DELETE FROM WalletInfo
WHERE walletInfoId NOT IN (
    SELECT MIN(walletInfoId)
    FROM WalletInfo
    GROUP BY id
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_walletinfo_id_unique
ON WalletInfo (id);
''');
    }
    if (oldVersion <= 2) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS BalanceCardStyleSettings (
  walletInfoId INTEGER,
  accountIndex INTEGER DEFAULT -1,
  gradientIndex INTEGER DEFAULT -1,
  useSpecialDesign BOOLEAN DEFAULT FALSE,
  backgroundImagePath TEXT DEFAULT "",
  PRIMARY KEY (walletInfoId, accountIndex),
  FOREIGN KEY (walletInfoId) REFERENCES WalletInfo(walletInfoId)
);
''');
      await _addColumnIfNotExists(
        db,
        table: 'WalletInfo',
        column: 'receiveInfoboxDismissed',
        definition: 'BOOLEAN DEFAULT FALSE',
      );

      await _addColumnIfNotExists(
        db,
        table: 'BalanceCardStyleSettings',
        column: 'cardOrder',
        definition: 'INTEGER DEFAULT 0',
      );
    }
    if (oldVersion <= 3) {
      await _addColumnIfNotExists(db,
          table: "WalletInfo", column: "showCombinedBalance", definition: "BOOLEAN DEFAULT TRUE");
      // null - primary token (eth, sol etc)
      // not null - address of fav token
      // if address doesn't correspond to a valid token, fallback to primary token
      await _addColumnIfNotExists(db,
          table: "WalletInfo", column: "favoriteTokenAddress", definition: "TEXT DEFAULT NULL");
    }

    if (oldVersion <= 4) {
      await _createBridgeTransferTable(db);
    }

    if (oldVersion <= 5) {
      await _createTradeTable(db);
    }
    if (oldVersion <= 6) {
      await _addColumnIfNotExists(
        db,
        table: 'Trade',
        column: 'toAddressExtraId',
        definition: 'TEXT',
      );
    }
    if (oldVersion <= 7) {
      await _createNodeTable(db);
    }
    if (oldVersion <= 8) {
      await _addColumnIfNotExists(
        db,
        table: 'BalanceCardStyleSettings',
        column: 'iconStyleIndex',
        definition: 'INTEGER DEFAULT 0',
      );
      await _addColumnIfNotExists(
        db,
        table: 'BalanceCardStyleSettings',
        column: 'isGradientOnly',
        definition: 'BOOLEAN DEFAULT FALSE',
      );
    }
  }, onCreate: (Database db, int version) async {
    await db.execute('''
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
  sortOrder INTEGER DEFAULT (0) NOT NULL,
  receiveInfoboxDismissed BOOLEAN DEFAULT FALSE,
  showCombinedBalance BOOLEAN DEFAULT TRUE,
  favoriteTokenAddress TEXT DEFAULT NULL
);
''');

    await db.execute('''
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

    await db.execute('''
CREATE TABLE WalletInfoAddress (
	walletInfoAddressId INTEGER PRIMARY KEY AUTOINCREMENT,
	walletInfoId INTEGER,
	"type" INTEGER NOT NULL,
	address TEXT NOT NULL,
	CONSTRAINT WalletInfoAddress_WalletInfo_FK FOREIGN KEY (walletInfoId) REFERENCES WalletInfo(walletInfoId)
);
''');

    await db.execute('''
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

    await db.execute('''
CREATE TABLE "WalletInfoAddressMap" (
	walletInfoAddressMapId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	walletInfoId INTEGER NOT NULL,
	addressKey TEXT NOT NULL,
	addressValue TEXT NOT NULL,
	CONSTRAINT WalletInfoAddress_WalletInfo_FK FOREIGN KEY (walletInfoId) REFERENCES WalletInfo(walletInfoId)
);
        ''');
    await db.execute('''
CREATE UNIQUE INDEX IF NOT EXISTS idx_walletinfo_id_unique
ON WalletInfo (id);
''');
    await db.execute('''
CREATE TABLE BalanceCardStyleSettings (
  walletInfoId INTEGER,
  accountIndex INTEGER DEFAULT -1,
  gradientIndex INTEGER DEFAULT -1,
  useSpecialDesign BOOLEAN DEFAULT FALSE,
  backgroundImagePath TEXT DEFAULT "",
  iconStyleIndex INTEGER DEFAULT 0,
  isGradientOnly BOOLEAN DEFAULT FALSE,
  cardOrder INTEGER DEFAULT 0,
  PRIMARY KEY (walletInfoId, accountIndex),
  FOREIGN KEY (walletInfoId) REFERENCES WalletInfo(walletInfoId)
);
        ''');
    await _createBridgeTransferTable(db);
    await _createNodeTable(db);
    await _createTradeTable(db);
  });
}

Future<void> _createTradeTable(Database db) async {
  await db.execute('''
CREATE TABLE IF NOT EXISTS Trade (
  tradeId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  id TEXT NOT NULL,
  providerRaw INTEGER NOT NULL DEFAULT 0,
  fromTitle TEXT,
  fromName TEXT,
  fromTag TEXT,
  fromFullName TEXT,
  fromDecimals INTEGER,
  fromRaw INTEGER,
  fromIconPath TEXT,
  fromFlatIconPath TEXT,
  fromChainIconPath TEXT,
  toTitle TEXT,
  toName TEXT,
  toTag TEXT,
  toFullName TEXT,
  toDecimals INTEGER,
  toRaw INTEGER,
  toIconPath TEXT,
  toFlatIconPath TEXT,
  toChainIconPath TEXT,
  stateRaw TEXT NOT NULL DEFAULT '',
  createdAt INTEGER,
  expiredAt INTEGER,
  amount TEXT NOT NULL DEFAULT '',
  receiveAmount TEXT,
  inputAddress TEXT,
  extraId TEXT,
  outputTransaction TEXT,
  refundAddress TEXT,
  walletId TEXT,
  payoutAddress TEXT,
  toAddressExtraId TEXT,
  password TEXT,
  providerId TEXT,
  providerName TEXT,
  fromWalletAddress TEXT,
  memo TEXT,
  txId TEXT,
  isRefund INTEGER DEFAULT 0,
  isSendAll INTEGER DEFAULT 0,
  router TEXT,
  needToRegisterInSwapXyz INTEGER DEFAULT 0,
  sourceTokenAddress TEXT,
  sourceTokenDecimals INTEGER,
  routerData TEXT,
  routerValue TEXT,
  routerChainId INTEGER,
  sourceTokenAmountRaw TEXT,
  requiresTokenApproval INTEGER DEFAULT 0,
  chainId INTEGER,
  fee REAL
);
''');
  await db.execute('''
CREATE UNIQUE INDEX IF NOT EXISTS idx_trade_id_unique
ON Trade (id);
''');
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

Future<List<String>> _getTableNames(Database db) async {
  final tableNames = await db.rawQuery('SELECT name FROM sqlite_master WHERE type = "table"');
  return tableNames.map((e) => (e["name"]).toString()).toList();
}

Future<Map<String, dynamic>> _dumpDb() async {
  final tableNames = await _getTableNames(db!);
  final ret = <String, dynamic>{};
  for (final tableName in tableNames) {
    ret[tableName] = await db!.query(tableName);
  }
  return ret;
}

Future<Map<String, dynamic>> dumpCustomDb(String path) async {
  final db = await openDatabase(path);
  final tableNames = await _getTableNames(db);
  final ret = <String, dynamic>{};
  for (final tableName in tableNames) {
    ret[tableName] = await db.query(tableName);
  }
  return ret;
}

Future<void> _createBridgeTransferTable(Database db) async {
  await db.execute('''
CREATE TABLE IF NOT EXISTS BridgeTransfer (
  id TEXT NOT NULL PRIMARY KEY,
  wallet_id TEXT NOT NULL,
  source_chain_id INTEGER NOT NULL,
  destination_chain_id INTEGER NOT NULL,
  token_symbol TEXT NOT NULL,
  token_contract TEXT NOT NULL,
  amount TEXT NOT NULL,
  recipient_address TEXT NOT NULL,
  source_tx_hash TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  confirmed_at INTEGER,
  amount_raw TEXT,
  error_message TEXT,
  status_message TEXT
);
''');
  await db.execute('''
CREATE INDEX IF NOT EXISTS idx_bridgetransfer_wallet_id
ON BridgeTransfer(wallet_id);
''');
}

Future<void> _createNodeTable(Database db) async {
  db.execute("""
CREATE TABLE Node (
NodeId INTEGER PRIMARY KEY,
uri TEXT NOT NULL,
path TEXT,
login TEXT,
label TEXT,
password TEXT,
isPow INTEGER NOT NULL,
useSSL INTEGER,
typeRaw INTEGER NOT NULL,
trusted INTEGER NOT NULL,
socksProxyAddress TEXT,
isEnabledForAutoSwitching BOOLEAN DEFAULT FALSE,
isOfficial BOOLEAN DEFAULT FALSE,
isBuiltin BOOLEAN DEFAULT FALSE,
isDefault BOOLEAN DEFAULT FALSE
);
        """);
}
