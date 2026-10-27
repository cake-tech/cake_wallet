import "package:sqflite_common_ffi/sqflite_ffi.dart";

const _alwaysDeleteTableNames = ["PriceData"];

const _deleteByNameTableNames = {
  "Erc20Token": "walletName",
  "SPLToken": "walletName",
  "TronToken": "walletName",
  "ImportedNFT": "walletName",
  "BridgeTransfer": "wallet_id",
};

const _deleteByIdTableNames = {"Trade": "walletId"};

const _deleteByWalletInfoIdTableNames = {
  "WalletInfoAddress": "walletInfoId",
  "WalletInfoAddressInfo": "walletInfoId",
  "WalletInfoAddressMap": "walletInfoId",
  "BalanceCardStyleSettings": "walletInfoId",
  "WalletInfoAccount": "walletInfoId",
  "WalletInfo": "walletInfoId",
};

const _deleteByDerivationInfoIdTableNames = {
  "WalletInfoDerivationInfo": "walletInfoDerivationInfoId",
};

Future<Set<String>> _tableNames(DatabaseExecutor db) async => (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    ))
        .map((row) => row["name"]! as String)
        .toSet();

Future<void> _ensureIntact(Database db, String path) async {
  final result = await db.rawQuery("PRAGMA quick_check");
  if (result.isEmpty || result.first.values.first != "ok") {
    throw StateError("Database copy at $path is not consistent");
  }
}

Future<void> _deleteRows(
  Transaction txn,
  Set<String> tables,
  Map<String, String> tableColumns,
  Set<Object> values,
) async {
  if (values.isEmpty) return;
  for (final MapEntry(key: table, value: column) in tableColumns.entries) {
    if (!tables.contains(table)) continue;
    await txn.delete(
      table,
      where: '"$column" IN (${List.filled(values.length, "?").join(", ")})',
      whereArgs: values.toList(),
    );
  }
}

Future<void> trimDatabaseCopyForBackup(String path, {required Set<String> keepWalletIds}) async {
  final db = await openDatabase(path, singleInstance: false);
  try {
    await _ensureIntact(db, path);
    final tables = await _tableNames(db);
    final wallets = await db.query(
      "WalletInfo",
      columns: ["walletInfoId", "id", "name", "walletInfoDerivationInfoId"],
    );
    final kept = wallets.where((row) => keepWalletIds.contains(row["id"]));
    final removed = wallets.where((row) => !keepWalletIds.contains(row["id"]));
    Set<Object> removedOnly(String column) => removed
        .map((row) => row[column])
        .nonNulls
        .toSet()
        .difference(kept.map((row) => row[column]).nonNulls.toSet());

    await db.transaction((txn) async {
      for (final table in _alwaysDeleteTableNames.where(tables.contains)) {
        await txn.delete(table);
      }
      await _deleteRows(txn, tables, _deleteByNameTableNames, removedOnly("name"));
      await _deleteRows(txn, tables, _deleteByIdTableNames, removedOnly("id"));
      await _deleteRows(txn, tables, _deleteByWalletInfoIdTableNames, removedOnly("walletInfoId"));
      await _deleteRows(
        txn,
        tables,
        _deleteByDerivationInfoIdTableNames,
        removedOnly("walletInfoDerivationInfoId"),
      );
    });
    await db.execute("VACUUM");
  } finally {
    await db.close();
  }
}
