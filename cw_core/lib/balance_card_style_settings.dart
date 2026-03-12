import 'package:cw_core/card_design.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:sqflite/sqflite.dart';

class BalanceCardStyleSettings {
  final int walletInfoId;
  final int accountIndex;
  final int gradientIndex;
  final bool useSpecialDesign;
  final bool hidden;
  final String backgroundImagePath;
  final int cardOrder;

  BalanceCardStyleSettings(
      {required this.walletInfoId,
        required this.accountIndex,
        required this.gradientIndex,
        required this.useSpecialDesign,
        required this.hidden,
        required this.backgroundImagePath,
        required this.cardOrder});

  static const tableName = "BalanceCardStyleSettings";

  Map<String, dynamic> toJson() {
    final ret = {
      "walletInfoId": walletInfoId,
      "accountIndex": accountIndex,
      "gradientIndex": gradientIndex,
      "hidden": hidden ? 1 : 0,
      "useSpecialDesign": useSpecialDesign ? 1 : 0,
      "backgroundImagePath": backgroundImagePath,
      "cardOrder": cardOrder,
    };
    return ret;
  }

  static BalanceCardStyleSettings fromJson(Map<String, dynamic> json) {
    return BalanceCardStyleSettings(
      walletInfoId: json["walletInfoId"] as int,
      accountIndex: json["accountIndex"] as int,
      hidden: json["hidden"] == 1,
      gradientIndex: json["gradientIndex"] as int,
      useSpecialDesign: json["useSpecialDesign"] == 1,
      backgroundImagePath: json["backgroundImagePath"] as String? ?? "",
      cardOrder: json["cardOrder"] as int? ?? -1,
    );
  }

  BalanceCardStyleSettings copyWith({
    int? walletInfoId,
    int? accountIndex,
    int? gradientIndex,
    bool? useSpecialDesign,
    bool? hidden,
    String? backgroundImagePath,
    int? cardOrder,
  }) {
    return BalanceCardStyleSettings(
      walletInfoId: walletInfoId ?? this.walletInfoId,
      accountIndex: accountIndex ?? this.accountIndex,
      gradientIndex: gradientIndex ?? this.gradientIndex,
      useSpecialDesign: useSpecialDesign ?? this.useSpecialDesign,
      hidden: hidden ?? this.hidden,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      cardOrder: cardOrder ?? this.cardOrder,
    );
  }

  static BalanceCardStyleSettings fromCardDesign(
      int walletInfoId, int accountIndex, int cardOrder, CardDesign design, {bool hidden = false}) {
    return BalanceCardStyleSettings(
      walletInfoId: walletInfoId,
      accountIndex: accountIndex,
      gradientIndex: CardDesign.allGradients.indexOf(design.gradient),
      useSpecialDesign: design.backgroundType == CardDesignBackgroundTypes.svgFull,
      hidden: hidden,
      backgroundImagePath:
      design.backgroundType == CardDesignBackgroundTypes.image ? design.imagePath : "",
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