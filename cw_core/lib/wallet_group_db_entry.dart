import 'package:cw_core/db/sqlite.dart';
import 'package:sqflite/sqflite.dart';

class WalletGroupDbEntry {
  WalletGroupDbEntry(
    this.id,
    this.name,
    this.iconType,
    this.iconValue,
    this.iconColor,
    this.iconBg,
  );

  factory WalletGroupDbEntry.external({
    required String id,
    String? name,
    String? iconType,
    String? iconValue,
    String? iconColor,
    String? iconBg,
  }) =>
      WalletGroupDbEntry(id, name, iconType, iconValue, iconColor, iconBg);

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

  factory WalletGroupDbEntry.fromJson(Map<String, dynamic> json) => WalletGroupDbEntry(
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

  static Future<int> updateName(String id, String name) =>
      db!.update(tableName, {'name': name}, where: 'id = ?', whereArgs: [id]);

  static Future<int> updateIcon(
    String id, {
    required String iconType,
    required String iconValue,
    required String iconColor,
    required String iconBg,
  }) =>
      db!.update(
        tableName,
        {
          'iconType': iconType,
          'iconValue': iconValue,
          'iconColor': iconColor,
          'iconBg': iconBg,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

  static Future<bool> nameExists(String name, {String? excludeId}) async {
    final rows = await db!.rawQuery(
      'SELECT 1 FROM $tableName WHERE lower(trim(name)) = lower(?) AND id != ? LIMIT 1',
      [name.trim(), excludeId ?? ''],
    );
    return rows.isNotEmpty;
  }

  static Future<List<WalletGroupDbEntry>> getAll() async {
    final list = await db!.query(tableName);
    return List.generate(list.length, (index) => WalletGroupDbEntry.fromJson(list[index]));
  }

  static Future<WalletGroupDbEntry?> get(String id) async {
    final list = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (list.isEmpty) {
      return null;
    }
    return WalletGroupDbEntry.fromJson(list[0]);
  }

  static Future<void> delete(String id) async {
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
