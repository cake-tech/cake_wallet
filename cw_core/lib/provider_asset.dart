import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

// every provider has their own way of describing the available assets
// we store them here and provide a list when needed
// the less stable alternative would be rebuilding them from ExternalCurrency objects
class ProviderAsset {
  const ProviderAsset({
    required this.provider,
    required this.assetKey,
    required this.ticker,
    required this.network,
    this.assetId,
    this.decimals,
  });

  ProviderAsset.fromMap(Map<String, Object?> map)
    : this(
        provider: map["provider"]! as int,
        assetKey: map["assetKey"]! as String,
        ticker: map["ticker"]! as String,
        network: map["network"]! as String,
        assetId: map["assetId"] as String?,
        decimals: map["decimals"] as int?,
      );

  static const tableName = "ProviderAsset";

  final int provider;
  final String assetKey;
  final String ticker;
  final String network;
  final String? assetId;
  final int? decimals;

  ProviderAsset copyWith({String? assetKey}) => ProviderAsset(
    provider: provider,
    assetKey: assetKey ?? this.assetKey,
    ticker: ticker,
    network: network,
    assetId: assetId,
    decimals: decimals,
  );

  Map<String, Object?> toMap() => {
    "provider": provider,
    "assetKey": assetKey,
    "ticker": ticker,
    "network": network,
    "assetId": assetId,
    "decimals": decimals,
  };

  static Future<List<ProviderAsset>> getAll() async =>
      (await db!.query(tableName)).map(ProviderAsset.fromMap).toList();

  static Future<void> replace(
    Map<int, List<ProviderAsset>> rowsByProvider, {
    Map<String, String> renamedKeys = const {},
  }) => db!.transaction((txn) async {
    final batch = txn.batch();
    for (final MapEntry(key: oldKey, value: newKey) in renamedKeys.entries) {
      batch.update(
        tableName,
        {"assetKey": newKey},
        where: "assetKey = ?",
        whereArgs: [oldKey],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final MapEntry(key: provider, value: rows) in rowsByProvider.entries) {
      batch.delete(tableName, where: "provider = ?", whereArgs: [provider]);
      for (final row in rows) {
        batch.insert(tableName, row.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  });
}
