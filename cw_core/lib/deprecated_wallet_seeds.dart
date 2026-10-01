import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class DeprecatedWalletSeeds {
  DeprecatedWalletSeeds({required this.walletInfoId, required this.seed});

  DeprecatedWalletSeeds.fromJson(Map<String, dynamic> json)
      : walletInfoId = json["walletInfoId"] as int,
        seed = json["seed"] as String;

  Map<String, dynamic> toJson() => {
    "walletInfoId": walletInfoId,
    "seed": seed,
  };

  Future<void> save() =>
      db!.insert(tableName, toJson(), conflictAlgorithm: ConflictAlgorithm.replace);

  static const tableName = "DeprecatedWalletSeeds";

  final int walletInfoId;
  final String seed;

  static Future<List<DeprecatedWalletSeeds>> selectList(String where, List<dynamic> whereArgs,) async {
    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
    return List.generate(list.length, (index) => DeprecatedWalletSeeds.fromJson(list[index]));
  }

  static Future<DeprecatedWalletSeeds?> get(int walletInfoId) async =>
      (await selectList("walletInfoId = ?", [walletInfoId])).firstOrNull;
}
