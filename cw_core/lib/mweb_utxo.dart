import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class MwebUtxo {
  MwebUtxo({
    required this.walletInfoId,
    required this.height,
    required this.value,
    required this.address,
    required this.outputId,
    required this.blockTime,
    this.spent = false,
  });

  MwebUtxo.fromMap(Map<String, dynamic> map)
      : walletInfoId = map["walletInfoId"] as int,
        height = map["height"] as int,
        value = map["value"] as int,
        address = map["address"] as String,
        outputId = map["outputId"] as String,
        blockTime = map["blockTime"] as int,
        spent = _getBoolFromDB(map["spent"], defaultValue: false);

  Map<String, dynamic> toMap() => {
        "walletInfoId": walletInfoId,
        "height": height,
        "value": value,
        "address": address,
        "outputId": outputId,
        "blockTime": blockTime,
        "spent": spent ? 1 : 0,
      };

  static const tableName = "MwebUtxo";

  int walletInfoId;
  int height;
  int value;
  String address;
  String outputId;
  int blockTime;
  bool spent;

  static Future<List<MwebUtxo>> selectList(String where, List<dynamic> whereArgs,
      {String? orderBy,}) async {
    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return List.generate(list.length, (index) => MwebUtxo.fromMap(list[index]));
  }

  static Future<MwebUtxo?> select(String where, List<dynamic> whereArgs, {String? orderBy}) async {
    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return list.isEmpty ? null : MwebUtxo.fromMap(list.first);
  }

  static Future<List<MwebUtxo>> getAllForWallet(int walletInfoId) =>
      selectList("walletInfoId = ?", [walletInfoId]);

  static Future<MwebUtxo?> get(int walletInfoId, String outputId) =>
      select("walletInfoId = ? AND outputId = ?", [walletInfoId, outputId]);

  Future<void> save() => db!.insert(tableName, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<int> delete() => db!.delete(tableName,
      where: "walletInfoId = ? AND outputId = ?", whereArgs: [walletInfoId, outputId],);

  static Future<int> deleteAllForWallet(int walletInfoId) => db!.delete(tableName,
    where: "walletInfoId = ?", whereArgs: [walletInfoId],);

  static bool _getBoolFromDB(value, {bool? defaultValue}) {
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value == 1;
    } else {
      return defaultValue ?? false;
    }
  }
}
