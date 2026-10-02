import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

/// A token on Spark (Breez's settlement layer for Bitcoin/Lightning), identified by a
/// [tokenIdentifier] (a `btkn1...` BTKN-protocol token id) rather than a contract or mint
/// address. Attached to `WalletType.bitcoin` wallets that have Lightning enabled, the same
/// way [SPLToken] attaches to Solana wallets.
class SparkToken extends CryptoCurrency {
  SparkToken({
    required this.name,
    required this.symbol,
    required this.tokenIdentifier,
    required this.decimal,
    this.iconPath,
    this.tag = "BTC",
    bool enabled = true,
    this.isPotentialScam = false,
    super.groups,
    this.id = 0,
    this.walletName,
  })  : _enabled = enabled,
        super(
          name: symbol.toLowerCase(),
          title: symbol.toUpperCase(),
          fullName: name,
          tag: tag,
          iconPath: iconPath,
          decimals: decimal,
          isPotentialScam: isPotentialScam,
        );

  SparkToken.copyWith(
    SparkToken other, {
    String? icon,
    String? tag,
    bool? enabled,
    String? walletName,
  })  : name = other.name,
        symbol = other.symbol,
        tokenIdentifier = other.tokenIdentifier,
        decimal = other.decimal,
        _enabled = enabled ?? other.enabled,
        tag = tag ?? other.tag,
        iconPath = icon ?? other.iconPath,
        isPotentialScam = other.isPotentialScam,
        id = 0,
        walletName = walletName ?? other.walletName,
        super(
          title: other.symbol.toUpperCase(),
          name: other.symbol.toLowerCase(),
          decimals: other.decimal,
          fullName: other.name,
          tag: other.tag,
          iconPath: icon,
          isPotentialScam: other.isPotentialScam,
          groups: other.groups,
        );

  SparkToken.fromMap(Map<String, Object?> map)
      : this(
          name: map["name"] as String? ?? "",
          symbol: map["symbol"] as String? ?? "",
          tokenIdentifier: map["tokenIdentifier"] as String? ?? "",
          decimal: (map["decimal"] ?? 0) as int,
          enabled: _getBoolFromDB(map["enabled"], defaultValue: true),
          iconPath: map["iconPath"] as String?,
          tag: map["tag"] as String?,
          isPotentialScam: _getBoolFromDB(map["isPotentialScam"]),
          id: (map[selfIdColumn] ?? 0) as int,
          walletName: map["walletName"] as String?,
          groups: _groupsFromDB(map["groups"]),
        );

  static Set<String> _groupsFromDB(Object? value) {
    if (value is! String || value.isEmpty) {
      return const {};
    }

    return value.split(",").where((g) => g.isNotEmpty).toSet();
  }

  @override
  final String name;

  @override
  final String symbol;

  final String tokenIdentifier;

  final int decimal;

  bool _enabled;

  @override
  final String? iconPath;

  @override
  final String? tag;

  @override
  bool isPotentialScam;

  int id;
  String? walletName;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  static bool _getBoolFromDB(value, {bool? defaultValue}) {
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value == 1;
    } else {
      return defaultValue ?? false;
    }
  }

  Map<String, dynamic> toMap() => {
        selfIdColumn: id,
        "walletName": walletName,
        "name": name,
        "symbol": symbol,
        "tokenIdentifier": tokenIdentifier,
        "decimal": decimal,
        "enabled": _enabled ? 1 : 0,
        "iconPath": iconPath,
        "tag": tag,
        "isPotentialScam": isPotentialScam ? 1 : 0,
        "groups": groups.join(","),
      };

  static Database? _tableReadyFor;

  /// Created here rather than in `cw_core`'s migrations so builds without Bitcoin never carry
  /// this table. Idempotent; skipped once done for the currently open [db].
  static Future<void> _ensureTable() async {
    final database = db!;
    if (identical(_tableReadyFor, database)) return;
    await database.execute("""
CREATE TABLE IF NOT EXISTS SparkToken (
  SparkTokenId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  walletName TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  symbol TEXT NOT NULL DEFAULT '',
  tokenIdentifier TEXT NOT NULL,
  decimal INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1,
  iconPath TEXT,
  tag TEXT,
  isPotentialScam INTEGER NOT NULL DEFAULT 0,
  groups TEXT DEFAULT ''
);
""");
    await database.execute("""
CREATE UNIQUE INDEX IF NOT EXISTS idx_sparktoken_wallet_identifier
ON SparkToken (walletName, tokenIdentifier);
""");
    _tableReadyFor = database;
  }

  static String get tableName => "SparkToken";
  static String get selfIdColumn => "${tableName}Id";

  Future<int> save() async {
    if (walletName == null) {
      throw StateError("SparkToken.save() requires walletName to be set");
    }

    await _ensureTable();
    final json = toMap();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }

    id = await db!.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);

    return id;
  }

  static Future<List<SparkToken>> selectList(
    String where,
    List<dynamic> whereArgs, {
    String? orderBy,
  }) async {
    await _ensureTable();
    orderBy ??= selfIdColumn;

    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return List.generate(list.length, (index) => SparkToken.fromMap(list[index]));
  }

  static Future<List<SparkToken>> getAllForWallet(String walletName) =>
      selectList("walletName = ?", [walletName]);

  static Future<SparkToken?> getByIdentifier(String walletName, String tokenIdentifier) async {
    final list = await selectList(
      "walletName = ? AND tokenIdentifier = ?",
      [walletName, tokenIdentifier],
    );

    return list.isEmpty ? null : list.first;
  }

  static Future<int> deleteForWallet(String walletName, String tokenIdentifier) async {
    await _ensureTable();
    return db!.delete(
      tableName,
      where: "walletName = ? AND tokenIdentifier = ?",
      whereArgs: [walletName, tokenIdentifier],
    );
  }

  static Future<int> deleteAllForWallet(String walletName) async {
    await _ensureTable();
    return db!.delete(tableName, where: "walletName = ?", whereArgs: [walletName]);
  }

  static Future<void> renameWallet(String oldName, String newName) async {
    await _ensureTable();
    await db!.delete(tableName, where: "walletName = ?", whereArgs: [newName]);
    await db!
        .update(tableName, {"walletName": newName}, where: "walletName = ?", whereArgs: [oldName]);
  }

  @override
  bool operator ==(Object other) => other is SparkToken && other.tokenIdentifier == tokenIdentifier;

  @override
  int get hashCode => tokenIdentifier.hashCode;
}
