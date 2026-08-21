import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class Erc20Token extends CryptoCurrency {
  Erc20Token({
    required this.name,
    required this.symbol,
    required this.contractAddress,
    required this.decimal,
    bool enabled = true,
    this.iconPath,
    this.tag,
    this.isPotentialScam = false,
    this.id = 0,
    this.walletName,
    this.chainId,
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

  Erc20Token.copyWith(
    Erc20Token other, {
    String? icon,
    super.tag,
    bool? enabled,
    String? walletName,
    int? chainId,
  })  : name = other.name,
        symbol = other.symbol,
        contractAddress = other.contractAddress,
        decimal = other.decimal,
        _enabled = enabled ?? other.enabled,
        tag = tag ?? other.tag,
        iconPath = icon ?? other.iconPath,
        isPotentialScam = other.isPotentialScam,
        id = 0,
        walletName = walletName ?? other.walletName,
        chainId = chainId ?? other.chainId,
        super(
          name: other.name,
          title: other.symbol.toUpperCase(),
          fullName: other.name,
          iconPath: icon,
          decimals: other.decimal,
          isPotentialScam: other.isPotentialScam,
        );

  Erc20Token.fromMap(Map<String, Object?> map)
      : this(
          name: map["name"] as String? ?? "",
          symbol: map["symbol"] as String? ?? "",
          contractAddress: map["contractAddress"] as String? ?? "",
          decimal: (map["decimal"] ?? 0) as int,
          enabled: _getBoolFromDB(map["enabled"], defaultValue: true),
          iconPath: map["iconPath"] as String?,
          tag: map["tag"] as String?,
          isPotentialScam: _getBoolFromDB(map["isPotentialScam"]),
          id: (map[selfIdColumn] ?? 0) as int,
          walletName: map["walletName"] as String?,
          chainId: map["chainId"] as int?,
        );

  @override
  final String name;

  @override
  final String symbol;

  @override
  String? iconPath;

  @override
  final String? tag;

  @override
  bool isPotentialScam;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  int id;
  int? chainId;
  bool _enabled;
  final int decimal;
  String? walletName;
  final String contractAddress;

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
        "chainId": chainId,
        "name": name,
        "symbol": symbol,
        "contractAddress": contractAddress.toLowerCase(),
        "decimal": decimal,
        "enabled": _enabled ? 1 : 0,
        "iconPath": iconPath,
        "tag": tag,
        "isPotentialScam": isPotentialScam ? 1 : 0,
      };

  static String get tableName => "Erc20Token";
  static String get selfIdColumn => "${tableName}Id";

  Future<int> save() async {
    if (walletName == null || chainId == null) {
      throw StateError("Erc20Token.save() requires walletName and chainId to be set");
    }

    final json = toMap();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    id = await db!.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Erc20Token>> selectList(
    String where,
    List<dynamic> whereArgs, {
    String? orderBy,
  }) async {
    orderBy ??= selfIdColumn;
    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return List.generate(list.length, (index) => Erc20Token.fromMap(list[index]));
  }

  static Future<List<Erc20Token>> getAllForWallet(String walletName, int chainId) =>
      selectList("walletName = ? AND chainId = ?", [walletName, chainId]);

  static Future<Erc20Token?> getByContract(
    String walletName,
    int chainId,
    String contractAddress,
  ) async {
    final list = await selectList(
      "walletName = ? AND chainId = ? AND contractAddress = ?",
      [walletName, chainId, contractAddress.toLowerCase()],
    );
    return list.isEmpty ? null : list.first;
  }

  static Future<int> deleteForWallet(String walletName, int chainId, String contractAddress) =>
      db!.delete(
        tableName,
        where: "walletName = ? AND chainId = ? AND contractAddress = ?",
        whereArgs: [walletName, chainId, contractAddress.toLowerCase()],
      );

  static Future<int> deleteAllForWallet(String walletName) =>
      db!.delete(tableName, where: "walletName = ?", whereArgs: [walletName]);

  static Future<void> renameWallet(String oldName, String newName) async {
    await db!.delete(tableName, where: "walletName = ?", whereArgs: [newName]);
    await db!
        .update(tableName, {"walletName": newName}, where: "walletName = ?", whereArgs: [oldName]);
  }

  @override
  bool operator ==(Object other) => other is Erc20Token && other.contractAddress == contractAddress;

  @override
  int get hashCode => contractAddress.hashCode;

  int get chainId => switch (tag) {
        "ETH" => 1,
        "POL" => 137,
        "BASE" => 8453,
        "ARB" => 42161,
        "BSC" => 56,
        _ => throw ArgumentError()
      };

  @override
  String get serialized => "evm.$contractAddress.$chainId";
}
