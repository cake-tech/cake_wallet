import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";

class ExternalCurrency extends CryptoCurrency {
  ExternalCurrency({
    required this.assetKey,
    required super.title,
    required this.tag,
    this.id = 0,
    this.fullName,
    this.contractAddress,
    this.iconUrl,
    this.disabled = false,
    this.groups = const {},
  }) : super(name: title.toLowerCase(),
      decimals: 20 // providers don't provide decimals from api, 20 should be enough for everything
      );

  ExternalCurrency.fromMap(Map<String, Object?> map)
    : this(
        id: map[selfIdColumn]! as int,
        assetKey: map["assetKey"]! as String,
        title: map["title"]! as String,
        tag: map["tag"]! as String,
        fullName: map["fullName"] as String?,
        contractAddress: map["contractAddress"] as String?,
        iconUrl: map["iconUrl"] as String?,
        disabled: map["disabled"] == 1,
        groups: {
          for (final group in (map["groups"] as String? ?? "").split(","))
            if (group.isNotEmpty) group,
        },
      );


  static const tableName = "ExternalCurrency";
  static const selfIdColumn = "${tableName}Id";

  int id;

  @override
  String assetKey;
  String? contractAddress;
  String? iconUrl;
  bool disabled;

  @override
  final String tag;

  @override
  String? fullName;

  @override
  Set<String> groups;

  bool get isNative => assetKey.endsWith("/native");

  @override
  String? get iconPath => iconUrl;

  @override
  String get apiString => contractAddress != null ? "crypto.$contractAddress" : "crypto.$title";

  @override
  String get serialized => "ext^$id";

  Map<String, Object?> toMap() => {
    selfIdColumn: id == 0 ? null : id,
    "assetKey": assetKey,
    "title": title,
    "tag": tag,
    "fullName": fullName,
    "contractAddress": contractAddress,
    "iconUrl": iconUrl,
    "groups": groups.join(","),
    "disabled": disabled ? 1 : 0,
  };

  static Future<List<ExternalCurrency>> getAll() async =>
      (await db!.query(tableName, orderBy: selfIdColumn)).map(ExternalCurrency.fromMap).toList();

  static Future<ExternalCurrency?> getById(int id) async {
    final rows = await db!.query(tableName, where: "$selfIdColumn = ?", whereArgs: [id]);
    return rows.isEmpty ? null : ExternalCurrency.fromMap(rows.first);
  }

  static Future<void> saveAll(List<ExternalCurrency> currencies) async {
    if (currencies.isEmpty) {
      return;
    }

    final results = await db!.transaction((txn) {
      final batch = txn.batch();
      for (final currency in currencies) {
        if (currency.id == 0) {
          batch.insert(tableName, currency.toMap());
        } else {
          batch.update(
            tableName,
            currency.toMap(),
            where: "$selfIdColumn = ?",
            whereArgs: [currency.id],
          );
        }
      }
      return batch.commit();
    });

    for (final (index, currency) in currencies.indexed) {
      if (currency.id == 0) {
        currency.id = results[index]! as int;
      }
    }
  }

  @override
  bool operator ==(Object other) => other is ExternalCurrency && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
