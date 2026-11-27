import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class CoinNotesStore {
  static CoinNotesStore instance = CoinNotesStore();

  static const tableName = "CoinNote";

  Future<Map<String, String>> forWallet(int walletInfoId) async {
    final rows = await db!.query(tableName, where: "walletInfoId = ?", whereArgs: [walletInfoId]);
    return {
      for (final row in rows) row["id"]! as String: row["note"] as String? ?? "",
    };
  }

  Future<void> save(int walletInfoId, String id, String note) => db!.insert(
        tableName,
        {"walletInfoId": walletInfoId, "id": id, "note": note},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteWallet(int walletInfoId) =>
      db!.delete(tableName, where: "walletInfoId = ?", whereArgs: [walletInfoId]);
}
