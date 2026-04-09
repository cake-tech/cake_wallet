import 'package:cake_wallet/new-ui/model/charts/price_data.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:sqflite/sqflite.dart';

class ChartsAsset {
  final CryptoCurrency asset;
  final bool isFavorite;

  static const tableName = "ChartsAssets";

  Map<String, dynamic> toJson() => {"asset": asset.apiString, "isFavorite": isFavorite ? 1 : 0};

  static ChartsAsset fromJson(Map<String, dynamic> json) => ChartsAsset(
      asset: currencyFromApiString(json["asset"] as String) as CryptoCurrency,
      isFavorite: json["isFavorite"] != 0);

  static Future<List<ChartsAsset>> get() async {
    final json = await db!.query(tableName);
    return List.generate(json.length, (index) => ChartsAsset.fromJson(json[index]));
  }

  Future<void> insert() async {
    await db!.insert(tableName, toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove() async {
    await db!.delete(tableName, where: "asset = ?", whereArgs: [asset.apiString]);
  }

  const ChartsAsset({required this.asset, required this.isFavorite});
}
