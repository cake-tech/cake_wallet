import "package:cw_core/db/sqlite.dart" show db;

class UnilateralExitPlanStore {
  const UnilateralExitPlanStore({required this.walletId});

  final String walletId;

  static const _table = "UnilateralExitRecord";

  Future<void> _ensureTable() => db!.execute("""
CREATE TABLE IF NOT EXISTS $_table (
  walletId TEXT NOT NULL,
  exitId TEXT NOT NULL,
  plan TEXT NOT NULL,
  PRIMARY KEY (walletId, exitId)
);
""");

  /// Every exit of this wallet, as the JSON it was saved with.
  Future<List<String>> readAll() async {
    await _ensureTable();

    final rows = await db!.query(
      _table,
      columns: ["plan"],
      where: "walletId = ?",
      whereArgs: [walletId],
    );

    return rows.map((row) => row["plan"]! as String).toList();
  }

  Future<void> write(String exitId, String plan) async {
    await _ensureTable();

    await db!.rawInsert(
      "INSERT OR REPLACE INTO $_table (walletId, exitId, plan) VALUES (?, ?, ?)",
      [walletId, exitId, plan],
    );
  }

  Future<void> delete(String exitId) async {
    await _ensureTable();

    await db!.delete(
      _table,
      where: "walletId = ? AND exitId = ?",
      whereArgs: [walletId, exitId],
    );
  }
}
