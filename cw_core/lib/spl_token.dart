import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class SPLToken extends CryptoCurrency {
  SPLToken({
    required this.name,
    required this.symbol,
    required this.mintAddress,
    required this.decimal,
    required this.mint,
    this.iconPath,
    this.networkIconUrl,
    this.tag = "SOL",
    bool enabled = true,
    this.isPotentialScam = false,
    super.groups,
    this.id = 0,
    this.walletName,
  })  : _enabled = enabled,
        super(
          name: mint.toLowerCase(),
          title: symbol.toUpperCase(),
          fullName: name,
          tag: tag,
          iconPath: iconPath,
          decimals: decimal,
          isPotentialScam: isPotentialScam,
        );

  factory SPLToken.fromMetadata({
    required String name,
    required String mint,
    required String symbol,
    required String mintAddress,
    required int decimal,
    String? iconPath,
    bool isPotentialScam = false,
  }) =>
      SPLToken(
        name: name,
        symbol: symbol,
        mintAddress: mintAddress,
        decimal: decimal,
        mint: mint,
        iconPath: iconPath,
        isPotentialScam: isPotentialScam,
      );

  SPLToken.copyWith(SPLToken other, {String? icon, String? tag, bool? enabled, String? walletName})
      : name = other.name,
        symbol = other.symbol,
        mintAddress = other.mintAddress,
        decimal = other.decimal,
        _enabled = enabled ?? other.enabled,
        mint = other.mint,
        tag = tag ?? other.tag,
        iconPath = icon ?? other.iconPath,
        networkIconUrl = other.networkIconUrl,
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

  SPLToken.fromMap(Map<String, Object?> map)
      : this(
          name: map["name"] as String? ?? "",
          symbol: map["symbol"] as String? ?? "",
          mintAddress: map["mintAddress"] as String? ?? "",
          decimal: (map["decimal"] ?? 0) as int,
          mint: map["mint"] as String? ?? "",
          enabled: _getBoolFromDB(map["enabled"], defaultValue: true),
          iconPath: map["iconPath"] as String?,
          networkIconUrl: map["networkIconUrl"] as String?,
          tag: map["tag"] as String?,
          isPotentialScam: _getBoolFromDB(map["isPotentialScam"]),
          id: (map[selfIdColumn] ?? 0) as int,
          walletName: map["walletName"] as String?,
        );
  @override
  final String name;

  @override
  final String symbol;

  final String mintAddress;

  final int decimal;

  bool _enabled;

  final String mint;

  @override
  final String? iconPath;

  @override
  String? networkIconUrl;

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
        "mintAddress": mintAddress,
        "decimal": decimal,
        "mint": mint,
        "enabled": _enabled ? 1 : 0,
        "iconPath": iconPath,
        "networkIconUrl": networkIconUrl,
        "tag": tag,
        "isPotentialScam": isPotentialScam ? 1 : 0,
      };

  static String get tableName => "SPLToken";
  static String get selfIdColumn => "${tableName}Id";

  Future<int> save() async {
    if (walletName == null) {
      throw StateError("SPLToken.save() requires walletName to be set");
    }

    final json = toMap();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    id = await db!.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<SPLToken>> selectList(String where, List<dynamic> whereArgs,
      {String? orderBy}) async {
    orderBy ??= selfIdColumn;
    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return List.generate(list.length, (index) => SPLToken.fromMap(list[index]));
  }

  static Future<List<SPLToken>> getAllForWallet(String walletName) async =>
      selectList("walletName = ?", [walletName]);

  static Future<SPLToken?> getByMint(String walletName, String mintAddress) async {
    final list = await selectList("walletName = ? AND mintAddress = ?", [walletName, mintAddress]);
    return list.isEmpty ? null : list.first;
  }

  static Future<int> deleteForWallet(String walletName, String mintAddress) => db!.delete(
        tableName,
        where: "walletName = ? AND mintAddress = ?",
        whereArgs: [walletName, mintAddress],
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
      (other is SPLToken && other.mintAddress == mintAddress) ||
      (other is CryptoCurrency && other.title == title);

  @override
  int get hashCode => mintAddress.hashCode;
}
