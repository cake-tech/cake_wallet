import 'package:cw_core/card_design.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:sqflite/sqflite.dart';

class BalanceCardStyleSettings {
  final int walletInfoId;
  final int accountIndex;
  final int gradientIndex;
  final bool useSpecialDesign;
  final String backgroundImagePath;
  final int iconStyleIndex;
  final bool isGradientOnly;
  final int cardOrder;

  BalanceCardStyleSettings(
      {required this.walletInfoId,
      required this.accountIndex,
      required this.gradientIndex,
      required this.useSpecialDesign,
      required this.backgroundImagePath,
      this.iconStyleIndex = 0,
      this.isGradientOnly = false,
      required this.cardOrder});

  static const tableName = "BalanceCardStyleSettings";

  Map<String, dynamic> toJson() {
    final ret = {
      "walletInfoId": walletInfoId,
      "accountIndex": accountIndex,
      "gradientIndex": gradientIndex,
      "useSpecialDesign": useSpecialDesign ? 1 : 0,
      "backgroundImagePath": backgroundImagePath,
      "iconStyleIndex": iconStyleIndex,
      "isGradientOnly": isGradientOnly ? 1 : 0,
      "cardOrder": cardOrder,
    };
    return ret;
  }

  static BalanceCardStyleSettings fromJson(Map<String, dynamic> json) {
    return BalanceCardStyleSettings(
      walletInfoId: json["walletInfoId"] as int,
      accountIndex: json["accountIndex"] as int,
      gradientIndex: json["gradientIndex"] as int,
      useSpecialDesign: json["useSpecialDesign"] == 1,
      backgroundImagePath: json["backgroundImagePath"] as String? ?? "",
      iconStyleIndex: json["iconStyleIndex"] as int? ?? 0,
      isGradientOnly: json["isGradientOnly"] == 1,
      cardOrder: json["cardOrder"] as int? ?? -1,
    );
  }

  static BalanceCardStyleSettings fromCardDesign({
    required int walletInfoId,
    required int accountIndex,
    required int cardOrder,
    required CardDesign design,
    int iconStyleIndex = 0,
    int? gradientIndexOverride,
  }) {
    final int gradientIndex =
        gradientIndexOverride ?? CardDesign.allGradients.indexOf(design.gradient);
    return BalanceCardStyleSettings(
      walletInfoId: walletInfoId,
      accountIndex: accountIndex,
      gradientIndex: gradientIndex,
      useSpecialDesign: design.backgroundType == CardDesignBackgroundTypes.svgFull,
      backgroundImagePath:
          design.backgroundType == CardDesignBackgroundTypes.image ? design.imagePath : "",
      iconStyleIndex: iconStyleIndex,
      isGradientOnly: design.backgroundType == CardDesignBackgroundTypes.gradientOnly,
      cardOrder: cardOrder,
    );
  }

  static Future<BalanceCardStyleSettings?> get(int walletInfoId, int accountIndex) async {
    final json = await db!.query(
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
    final json = await db!.query(
      tableName,
      where: "walletInfoId = ?",
      whereArgs: [walletInfoId],
    );
    return List.generate(json.length, (index) => BalanceCardStyleSettings.fromJson(json[index]));
  }

  Future<void> insert() async {
    db!.insert(tableName, toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
