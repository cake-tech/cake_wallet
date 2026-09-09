import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class FrozenCoinsStore {
  static FrozenCoinsStore instance = FrozenCoinsStore();

  static const tableName = "FrozenCoin";

  Future<Set<String>> frozenIds(String walletId) async {
    final rows = await db!.query(
      tableName,
      columns: ["id"],
      where: "walletId = ? AND frozen = 1",
      whereArgs: [walletId],
    );
    return rows.map((row) => row["id"]! as String).toSet();
  }

  Future<void> setFrozen(String walletId, String id, bool frozen) => db!.insert(
        tableName,
        {"walletId": walletId, "id": id, "frozen": frozen ? 1 : 0},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteWallet(String walletId) =>
      db!.delete(tableName, where: "walletId = ?", whereArgs: [walletId]);
}
