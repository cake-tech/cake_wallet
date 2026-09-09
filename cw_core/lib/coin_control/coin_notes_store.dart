import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class CoinNotesStore {
  static CoinNotesStore instance = CoinNotesStore();

  static const tableName = "CoinNote";

  Future<Map<String, String>> forWallet(String walletId) async {
    final rows = await db!.query(tableName, where: "walletId = ?", whereArgs: [walletId]);
    return {
      for (final row in rows) row["id"]! as String: row["note"] as String? ?? "",
    };
  }

  Future<void> save(String walletId, String id, String note) => db!.insert(
        tableName,
        {"walletId": walletId, "id": id, "note": note},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteWallet(String walletId) =>
      db!.delete(tableName, where: "walletId = ?", whereArgs: [walletId]);
}
