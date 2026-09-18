import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class FrozenCoinsStore {
  static FrozenCoinsStore instance = FrozenCoinsStore();

  static const tableName = "FrozenCoin";

  Future<Set<String>> frozenIds(int walletInfoId) async {
    final rows = await db!.query(
      tableName,
      columns: ["id"],
      where: "walletInfoId = ? AND frozen = 1",
      whereArgs: [walletInfoId],
    );
    return rows.map((row) => row["id"]! as String).toSet();
  }

  Future<void> setFrozen(int walletInfoId, String id, bool frozen) => db!.insert(
        tableName,
        {"walletInfoId": walletInfoId, "id": id, "frozen": frozen ? 1 : 0},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteWallet(int walletInfoId) =>
      db!.delete(tableName, where: "walletInfoId = ?", whereArgs: [walletInfoId]);
}
