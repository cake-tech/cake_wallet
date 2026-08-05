import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/model/charts/datetime_extension.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

Currency currencyFromApiString(String key) {
  final parts = key.split(".");
  final type = parts[0];
  final id = parts[1];

  switch (type) {
    case "fiat":
      return FiatCurrency.deserialize(raw: id);
    case "crypto":
      return CryptoCurrency.fromString(id);
    case "evm":
      throw UnimplementedError();
    case "sol":
      throw UnimplementedError();
  }
  throw Exception("unknown api string");
}

class PriceData implements Comparable<PriceData> {
  const PriceData({required this.time, required this.from, required this.to, required this.price});

  factory PriceData.fromJson(Map<String, dynamic> json) => PriceData(
        time: DateTimeX.fromSecondsSinceEpoch(json["timestamp"] as int),
        from: currencyFromApiString(json["fromCurrency"] as String),
        to: currencyFromApiString(json["toCurrency"] as String),
        price: json["price"] as String,
      );
  final DateTime time;
  final Currency from;
  final Currency to;
  final String price;

  static const tableName = "PriceData";

  Map<String, dynamic> toJson() => {
        "timestamp": time.secondsSinceEpoch.toString(),
        "price": price,
        "fromCurrency": from.apiString,
        "toCurrency": to.apiString,
      };

  static Future<List<PriceData>> get(
    Currency from,
    Currency to,
    DateTime? start,
    DateTime? end,
  ) async {
    final json = await db!.query(
      tableName,
      where: "fromCurrency = ? AND toCurrency = ? AND timestamp >= ? AND timestamp <= ?",
      whereArgs: [
        from.apiString,
        to.apiString,
        start?.secondsSinceEpoch ?? 0,
        // dart doesn't have INT_MAX, apparently.
        end?.secondsSinceEpoch ?? 0x7FFFFFFFFFFFFFFF,
      ],
    );
    return List.generate(json.length, (index) => PriceData.fromJson(json[index]));
  }

  Future<void> insert() async {
    await db!.insert(tableName, toJson(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> insertMany(Iterable<PriceData> data) async {
    if (data.isEmpty) {
      return;
    }

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

  @override
  int compareTo(PriceData other) => time.compareTo(other.time);
}
