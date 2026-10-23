import "package:sqflite_common_ffi/sqflite_ffi.dart";

const _walletInfoIdTables = [
  "WalletInfoAddress",
  "WalletInfoAddressInfo",
  "WalletInfoAddressMap",
  "BalanceCardStyleSettings",
  "WalletInfoAccount",
];

const _walletNameTables = ["Erc20Token", "SPLToken", "TronToken", "ImportedNFT"];

Future<Set<String>> _tableNames(DatabaseExecutor db) async => (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    ))
        .map((row) => row["name"] as String)
        .toSet();

Future<void> _ensureIntact(Database db, String path) async {
  final result = await db.rawQuery("PRAGMA quick_check");
  if (result.isEmpty || result.first.values.first != "ok") {
    throw StateError("Database copy at $path is not consistent");
  }
}

/// Removes every row that belongs to a wallet whose `WalletInfo.id` is not in
/// [keepWalletIds] from a copy of cake.db, drops cached price data, and
/// rebuilds the file so deleted rows can't be recovered from free pages.
Future<void> trimDatabaseCopyForBackup(String path, {required Set<String> keepWalletIds}) async {
  final db = await openDatabase(path, singleInstance: false);
  try {
    await _ensureIntact(db, path);
    final tables = await _tableNames(db);
    final wallets = await db.query(
      "WalletInfo",
      columns: ["walletInfoId", "id", "name", "walletInfoDerivationInfoId"],
    );
    final keptNames = wallets
        .where((row) => keepWalletIds.contains(row["id"]))
        .map((row) => row["name"] as String)
        .toSet();
    final removed = wallets.where((row) => !keepWalletIds.contains(row["id"]));

    await db.transaction((txn) async {
      for (final row in removed) {
        final walletInfoId = row["walletInfoId"];
        for (final table in _walletInfoIdTables.where(tables.contains)) {
          await txn.delete(table, where: "walletInfoId = ?", whereArgs: [walletInfoId]);
        }
        if (tables.contains("WalletInfoDerivationInfo")) {
          await txn.delete(
            "WalletInfoDerivationInfo",
            where: "walletInfoDerivationInfoId = ?",
            whereArgs: [row["walletInfoDerivationInfoId"]],
          );
        }
        if (tables.contains("Trade")) {
          await txn.delete("Trade", where: "walletId = ?", whereArgs: [row["id"]]);
        }
        final name = row["name"] as String;
        if (!keptNames.contains(name)) {
          for (final table in _walletNameTables.where(tables.contains)) {
            await txn.delete(table, where: "walletName = ?", whereArgs: [name]);
          }
          if (tables.contains("BridgeTransfer")) {
            await txn.delete("BridgeTransfer", where: "wallet_id = ?", whereArgs: [name]);
          }
        }
        await txn.delete("WalletInfo", where: "walletInfoId = ?", whereArgs: [walletInfoId]);
      }
      if (tables.contains("PriceData")) {
        await txn.delete("PriceData");
      }
    });
    await db.execute("VACUUM");
  } finally {
    await db.close();
  }
}

/// Looks up account ids by name in a copy of an account database (zkool).
Future<Map<String, int>> accountIdsByName(String path) async {
  final db = await openDatabase(path, singleInstance: false, readOnly: true);
  try {
    final rows = await db.rawQuery("SELECT id_account, name FROM accounts");
    return {for (final row in rows) row["name"] as String: row["id_account"] as int};
  } finally {
    await db.close();
  }
}

/// Keeps only the accounts in [keepAccountIds] in a copy of an account
/// database (zkool's zec.*.db or the legacy ywallet zec.db): `accounts` is
/// filtered by `id_account`, every other table that has an `account` column
/// by that column. The file is rebuilt afterwards so removed keys are gone.
Future<void> pruneAccountDatabaseCopy(String path, {required Set<int> keepAccountIds}) async {
  final db = await openDatabase(path, singleInstance: false);
  try {
    await _ensureIntact(db, path);
    final keep = keepAccountIds.join(",");
    final tables = await _tableNames(db);
    await db.transaction((txn) async {
      for (final table in tables) {
        final columns = (await txn.rawQuery('PRAGMA table_info("$table")'))
            .map((row) => row["name"] as String)
            .toSet();
        if (table == "accounts" && columns.contains("id_account")) {
          await txn.rawDelete('DELETE FROM "$table" WHERE id_account NOT IN ($keep)');
        } else if (columns.contains("account")) {
          await txn.rawDelete('DELETE FROM "$table" WHERE account NOT IN ($keep)');
        }
      }
    });
    await db.execute("VACUUM");
  } finally {
    await db.close();
  }
}
