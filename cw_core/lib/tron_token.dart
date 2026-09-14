import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class TronToken extends CryptoCurrency {
  TronToken({
    required this.name,
    required this.symbol,
    required this.contractAddress,
    required this.decimal,
    bool enabled = true,
    this.iconPath,
    this.networkIconUrl,
    this.tag = "TRX",
    this.isPotentialScam = false,
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
  TronToken.fromMap(Map<String, Object?> map)
      : this(
          name: map["name"] as String? ?? "",
          symbol: map["symbol"] as String? ?? "",
          contractAddress: map["contractAddress"] as String? ?? "",
          decimal: (map["decimal"] ?? 0) as int,
          enabled: _getBoolFromDB(map["enabled"], defaultValue: true),
          iconPath: map["iconPath"] as String?,
          networkIconUrl: map["networkIconUrl"] as String?,
          tag: map["tag"] as String?,
          isPotentialScam: _getBoolFromDB(map["isPotentialScam"]),
          id: (map[selfIdColumn] ?? 0) as int,
          walletName: map["walletName"] as String?,
        );

  TronToken.copyWith(
    TronToken other, {
    String? icon,
    String? tag,
    bool? enabled,
    String? walletName,
  })  : name = other.name,
        symbol = other.symbol,
        contractAddress = other.contractAddress,
        decimal = other.decimal,
        _enabled = enabled ?? other.enabled,
        tag = tag ?? other.tag,
        iconPath = icon ?? other.iconPath,
        networkIconUrl = other.networkIconUrl,
        isPotentialScam = other.isPotentialScam,
        id = 0,
        walletName = walletName ?? other.walletName,
        super(
          name: other.name,
          title: other.symbol.toUpperCase(),
          fullName: other.name,
          tag: tag ?? other.tag,
          iconPath: icon ?? other.iconPath,
          decimals: other.decimal,
          isPotentialScam: other.isPotentialScam,
        );
  @override
  final String name;

  @override
  final String symbol;

  @override
  final String? iconPath;

  @override
  String? networkIconUrl;

  @override
  final String? tag;

  @override
  final bool isPotentialScam;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  int id;
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
        "name": name,
        "symbol": symbol,
        "contractAddress": contractAddress,
        "decimal": decimal,
        "enabled": _enabled ? 1 : 0,
        "iconPath": iconPath,
        "networkIconUrl": networkIconUrl,
        "tag": tag,
        "isPotentialScam": isPotentialScam ? 1 : 0,
      };

  static String get tableName => "TronToken";
  static String get selfIdColumn => "${tableName}Id";

  Future<int> save() async {
    if (walletName == null) {
      throw StateError("TronToken.save() requires walletName to be set");
    }

    final json = toMap();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    id = await db!.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<TronToken>> selectList(
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
    return List.generate(list.length, (index) => TronToken.fromMap(list[index]));
  }

  static Future<List<TronToken>> getAllForWallet(String walletName) =>
      selectList("walletName = ?", [walletName]);

  static Future<TronToken?> getByContract(String walletName, String contractAddress) async {
    final list =
        await selectList("walletName = ? AND contractAddress = ?", [walletName, contractAddress]);
    return list.isEmpty ? null : list.first;
  }

  static Future<int> deleteForWallet(String walletName, String contractAddress) => db!.delete(
        tableName,
        where: "walletName = ? AND contractAddress = ?",
        whereArgs: [walletName, contractAddress],
      );

  static Future<int> deleteAllForWallet(String walletName) =>
      db!.delete(tableName, where: "walletName = ?", whereArgs: [walletName]);

  static Future<void> renameWallet(String oldName, String newName) async {
    await db!.delete(tableName, where: "walletName = ?", whereArgs: [newName]);
    await db!
        .update(tableName, {"walletName": newName}, where: "walletName = ?", whereArgs: [oldName]);
  }

  @override
  bool operator ==(other) =>
      (other is TronToken && other.contractAddress == contractAddress) ||
      (other is CryptoCurrency && other.title == title);

  @override
  int get hashCode => contractAddress.hashCode;
}
