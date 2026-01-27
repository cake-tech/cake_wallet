import 'package:cw_core/card_design.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:sqflite/sqflite.dart';

class BalanceCardStyleSettings {
  final int walletInfoId;
  final int accountIndex;
  final int gradientIndex;
  final bool useSpecialDesign;
  final String backgroundImagePath;

  BalanceCardStyleSettings(
      {required this.walletInfoId,
        required this.accountIndex,
        required this.gradientIndex,
        required this.useSpecialDesign,
        required this.backgroundImagePath});

  static const tableName = "BalanceCardStyleSettings";

  Map<String, dynamic> toJson() {
    return {
      "walletInfoId": walletInfoId,
      "accountIndex": accountIndex,
      "gradientIndex": gradientIndex,
      "useSpecialDesign": useSpecialDesign,
      "backgroundImagePath": backgroundImagePath,
    };
  }

  static BalanceCardStyleSettings fromJson(Map<String, dynamic> json) {
    return BalanceCardStyleSettings(
      walletInfoId: json["walletInfoId"] as int,
      accountIndex: json["accountIndex"] as int,
      gradientIndex: json["gradientIndex"] as int,
      useSpecialDesign: json["useSpecialDesign"] == 1,
      backgroundImagePath: json["backgroundImagePath"] as String? ?? "",
    );
  }

  static BalanceCardStyleSettings fromCardDesign(
      int walletInfoId, int accountIndex, CardDesign design) {
    return BalanceCardStyleSettings(
      walletInfoId: walletInfoId,
      accountIndex: accountIndex,
      gradientIndex: CardDesign.allGradients.indexOf(design.gradient),
      useSpecialDesign: design.backgroundType == CardDesignBackgroundTypes.svgFull,
      backgroundImagePath:
      design.backgroundType == CardDesignBackgroundTypes.image ? design.imagePath : "",
    );
  }

  static Future<BalanceCardStyleSettings?> get(int walletInfoId, int accountIndex) async {
    final json = await db.query(
      tableName,
      where: "walletInfoId = ? AND accountIndex = ?",
      whereArgs: [walletInfoId, accountIndex],
    );

    if (json.isEmpty) {
      return null;
    }

    return fromJson(json.first);
  }

  static Future<List<BalanceCardStyleSettings>> getAll(int walletInfoId) async {
    final json = await db.query(
      tableName,
      where: "walletInfoId = ?",
      whereArgs: [walletInfoId],
    );
    return List.generate(json.length, (index) => BalanceCardStyleSettings.fromJson(json[index]));
  }

  Future<void> insert() async {
    db.insert(tableName, toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}