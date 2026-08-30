import 'package:cw_core/db/sqlite.dart';
import 'package:sqflite/sqflite.dart';

class WalletGroup {
  WalletGroup(
    this.id,
    this.name,
    this.iconType,
    this.iconValue,
    this.iconColor,
    this.iconBg,
  );

  factory WalletGroup.external({
    required String id,
    String? name,
    String? iconType,
    String? iconValue,
    String? iconColor,
    String? iconBg,
  }) =>
      WalletGroup(id, name, iconType, iconValue, iconColor, iconBg);

  final String id;
  String? name;
  String? iconType;
  String? iconValue;
  String? iconColor;
  String? iconBg;

  static String get tableName => 'walletGroup';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconType': iconType,
        'iconValue': iconValue,
        'iconColor': iconColor,
        'iconBg': iconBg,
      };

  factory WalletGroup.fromJson(Map<String, dynamic> json) => WalletGroup(
        json['id'] as String,
        json['name'] as String?,
        json['iconType'] as String?,
        json['iconValue'] as String?,
        json['iconColor'] as String?,
        json['iconBg'] as String?,
      );

  Future<void> save() async {
    await db!.insert(tableName, toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<WalletGroup>> getAll() async {
    final list = await db!.query(tableName);
    return List.generate(list.length, (index) => WalletGroup.fromJson(list[index]));
  }

  static Future<WalletGroup?> get(String id) async {
    final list = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (list.isEmpty) {
      return null;
    }
    return WalletGroup.fromJson(list[0]);
  }

  static Future<void> delete(String id) async {
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}

