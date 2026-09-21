import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class ImportedNFT {
  ImportedNFT({
    required this.walletName,
    required this.chain,
    required this.identifier,
    this.name,
    this.symbol,
    this.description,
    this.imageUrl,
    this.isOwned,
    this.id = 0,
  });

  ImportedNFT.copyWith(ImportedNFT other, {String? walletName})
      : id = 0,
        walletName = walletName ?? other.walletName,
        chain = other.chain,
        identifier = other.identifier,
        name = other.name,
        symbol = other.symbol,
        description = other.description,
        imageUrl = other.imageUrl,
        isOwned = other.isOwned;

  factory ImportedNFT.fromMap(Map<String, Object?> map) => ImportedNFT(
        id: map[selfIdColumn] as int? ?? 0,
        walletName: map["walletName"]! as String,
        chain: map["chain"]! as String,
        identifier: map["identifier"]! as String,
        name: map["name"] as String?,
        symbol: map["symbol"] as String?,
        description: map["description"] as String?,
        imageUrl: map["imageUrl"] as String?,
        isOwned: map["isOwned"] == null ? null : map["isOwned"] == 1,
      );

  int id;
  final String walletName;
  final String chain;
  final String identifier;
  final String? name;
  final String? symbol;
  final String? description;
  final String? imageUrl;
  final bool? isOwned;

  static String get tableName => "ImportedNFT";
  static String get selfIdColumn => "${tableName}Id";
  static const solanaChain = "solana";

  Map<String, Object?> toMap() => {
        selfIdColumn: id,
        "walletName": walletName,
        "chain": chain,
        "identifier": identifier,
        "name": name,
        "symbol": symbol,
        "description": description,
        "imageUrl": imageUrl,
        "isOwned": isOwned == null ? null : (isOwned! ? 1 : 0),
      };

  Future<int> save() async {
    final row = toMap();

    if (row[selfIdColumn] == 0) {
      row[selfIdColumn] = null;
    }

    id = await db!.insert(tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);

    return id;
  }

  static Future<int> updateMetadata(ImportedNFT nft) => db!.update(
        tableName,
        nft.toMap()..remove(selfIdColumn),
        where: "walletName = ? AND chain = ? AND identifier = ?",
        whereArgs: [nft.walletName, nft.chain, nft.identifier],
      );

  static Future<List<ImportedNFT>> getAllForWallet(String walletName, [String? chain]) async {
    final rows = await db!.query(
      tableName,
      where: chain == null ? "walletName = ?" : "walletName = ? AND chain = ?",
      whereArgs: chain == null ? [walletName] : [walletName, chain],
      orderBy: selfIdColumn,
    );

    return rows.map(ImportedNFT.fromMap).toList();
  }

  static Future<int> deleteOne(String walletName, String chain, String identifier) => db!.delete(
        tableName,
        where: "walletName = ? AND chain = ? AND identifier = ?",
        whereArgs: [walletName, chain, identifier],
      );

  static String _scope(List<String>? chains) =>
      chains == null ? "" : " AND chain IN (${List.filled(chains.length, "?").join(", ")})";

  static Future<int> deleteAllForWallet(String walletName, {List<String>? chains}) async {
    if (chains != null && chains.isEmpty) {
      return 0;
    }

    return db!.delete(
      tableName,
      where: "walletName = ?${_scope(chains)}",
      whereArgs: [walletName, ...?chains],
    );
  }

  static Future<void> renameWallet(
    String oldName,
    String newName, {
    List<String>? chains,
  }) async {
    if (chains != null && chains.isEmpty) {
      return;
    }

    await db!.delete(
      tableName,
      where: "walletName = ?${_scope(chains)}",
      whereArgs: [newName, ...?chains],
    );
    await db!.update(
      tableName,
      {"walletName": newName},
      where: "walletName = ?${_scope(chains)}",
      whereArgs: [oldName, ...?chains],
    );
  }
}
