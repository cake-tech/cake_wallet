import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/new-ui/model/charts/datetime_extension.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:sqflite/sqflite.dart';

Currency currencyFromApiString(String key) {
  final parts = key.split('.');
  final type = parts[0];
  final id = parts[1];

  switch (type) {
    case "fiat":
      return FiatCurrency.deserialize(raw: id);
    case "crypto":
      return CryptoCurrency.fromString(id);
    case "evm":
      throw UnimplementedError("i promise i'll take care of this, i really want a working build");
    case "sol":
      throw UnimplementedError();
  }
  throw Exception("unknown api string");
}

class PriceData {
  final DateTime time;
  final Currency from;
  final Currency to;
  final String price;

  static const tableName = "PriceData";

  Map<String, dynamic> toJson() => {
        "timestamp": time.secondsSinceEpoch.toString(),
        "price": price,
        "from_currency": from.apiString,
        "to_currency": to.apiString,
      };

  static PriceData fromJson(Map<String, dynamic> json) => PriceData(
      time: DateTimeX.fromSecondsSinceEpoch(json["timestamp"] as int),
      from: currencyFromApiString(json["from_currency"] as String),
      to: currencyFromApiString(json["to_currency"] as String),
      price: json["price"] as String);

  static Future<List<PriceData>> get(
      Currency from, Currency to, DateTime? start, DateTime? end) async {
    final json = await db!.query(tableName,
        where: "from_currency = ? AND to_currency = ? AND timestamp >= ? AND timestamp <= ?",
        whereArgs: [
          from.apiString,
          to.apiString,
          start?.secondsSinceEpoch ?? 0,
          // dart doesn't have INT_MAX, apparently.
          end?.secondsSinceEpoch ?? 0x7FFFFFFFFFFFFFFF
        ]);
    return List.generate(json.length, (index) => PriceData.fromJson(json[index]));
  }

  Future<void> insert() async {
    db!.insert(tableName, toJson(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> insertMany(Iterable<PriceData> data) async {
    if (data.isEmpty) return;

    final batch = db!.batch();

    for (final datum in data) {
      batch.insert(
        tableName,
        datum.toJson(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  bool operator ==(Object other) =>
      other is PriceData && time == other.time && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(time, from, to);

  const PriceData({required this.time, required this.from, required this.to, required this.price});
}