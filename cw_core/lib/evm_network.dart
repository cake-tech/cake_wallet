import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/node.dart";
import "package:cw_core/wallet_type.dart";
import "package:sqflite/sqflite.dart";

class EvmNetwork {
  EvmNetwork({
    required this.chainId,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.tag,
    required this.rpcUrl,
    this.failoverUrl,
    this.explorerUrl,
    this.iconUrl,
    this.isManual = false,
    this.isEnabled = false,
    this.enabledAt = 0,
  });

  EvmNetwork.fromMap(Map<String, Object?> map)
      : chainId = map["chainId"]! as int,
        name = map["name"] as String? ?? "",
        symbol = map["symbol"] as String? ?? "",
        decimals = (map["decimals"] ?? 18) as int,
        tag = map["tag"] as String? ?? "",
        rpcUrl = map["rpcUrl"] as String? ?? "",
        failoverUrl = map["failoverUrl"] as String?,
        explorerUrl = map["explorerUrl"] as String?,
        iconUrl = map["iconUrl"] as String?,
        isManual = map["isManual"] == 1,
        isEnabled = map["isEnabled"] == 1,
        enabledAt = (map["enabledAt"] ?? 0) as int;

  static String get tableName => "EvmNetwork";

  final int chainId;
  final String name;
  final String symbol;
  final int decimals;
  final String tag;
  final String rpcUrl;
  final String? failoverUrl;
  final String? explorerUrl;
  final String? iconUrl;
  final bool isManual;
  final bool isEnabled;
  final int enabledAt;

  EvmNetwork copyWith({
    String? symbol,
    int? decimals,
    String? tag,
    bool? isEnabled,
    int? enabledAt,
  }) =>
      EvmNetwork(
        chainId: chainId,
        name: name,
        symbol: symbol ?? this.symbol,
        decimals: decimals ?? this.decimals,
        tag: tag ?? this.tag,
        rpcUrl: rpcUrl,
        failoverUrl: failoverUrl,
        explorerUrl: explorerUrl,
        iconUrl: iconUrl,
        isManual: isManual,
        isEnabled: isEnabled ?? this.isEnabled,
        enabledAt: enabledAt ?? this.enabledAt,
      );

  EvmNetwork withRpcUrls(String rpcUrl, String? failoverUrl) => EvmNetwork(
        chainId: chainId,
        name: name,
        symbol: symbol,
        decimals: decimals,
        tag: tag,
        rpcUrl: rpcUrl,
        failoverUrl: failoverUrl,
        explorerUrl: explorerUrl,
        iconUrl: iconUrl,
        isManual: isManual,
        isEnabled: isEnabled,
        enabledAt: enabledAt,
      );

  EvmNetwork withUniqueTag(
    Iterable<EvmNetwork> savedNetworks, {
    EvmNetwork? beforeEdit,
    bool hasWallets = false,
  }) {
    if (beforeEdit != null && hasWallets) {
      return copyWith(tag: beforeEdit.tag);
    }

    final usedTags = {
      for (final currency in CryptoCurrency.all) ...[
        currency.title.toUpperCase(),
        if (currency.tag != null) currency.tag!.toUpperCase(),
      ],
      for (final other in savedNetworks)
        if (other.chainId != chainId && other.chainId != beforeEdit?.chainId) ...[
          other.tag.toUpperCase(),
          other.symbol.toUpperCase(),
        ],
    };

    return usedTags.contains(tag.toUpperCase()) ? copyWith(tag: "$tag-$chainId") : this;
  }

  Map<String, Object?> toMap() => {
        "chainId": chainId,
        "name": name,
        "symbol": symbol,
        "decimals": decimals,
        "tag": tag,
        "rpcUrl": rpcUrl,
        "failoverUrl": failoverUrl,
        "explorerUrl": explorerUrl,
        "iconUrl": iconUrl,
        "isManual": isManual ? 1 : 0,
        "isEnabled": isEnabled ? 1 : 0,
        "enabledAt": enabledAt,
      };

  Future<int> save() =>
      db!.insert(tableName, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> replaceNodes(DatabaseExecutor executor) async {
    await deleteNodes(executor);
    await _insertRpcNodes(executor);
  }

  Future<void> replaceRpcNodes(DatabaseExecutor executor, EvmNetwork? previous) async {
    final urls = {rpcUrl, failoverUrl, previous?.rpcUrl, previous?.failoverUrl}.nonNulls;
    for (final url in urls) {
      final node = rpcNode(url, chainId);
      await executor.delete(
        Node.tableName,
        where: "typeRaw = ? AND chainId = ? AND uri = ? AND path = ?",
        whereArgs: [serializeToInt(WalletType.evm), chainId, node.uriRaw, node.path],
      );
    }

    await _insertRpcNodes(executor);
  }

  Future<void> _insertRpcNodes(DatabaseExecutor executor) async {
    await _insertNode(executor, rpcUrl, isDefault: true);

    final failoverUrl = this.failoverUrl;
    if (failoverUrl != null) {
      await _insertNode(executor, failoverUrl, isDefault: false);
    }
  }

  Future<int> _insertNode(DatabaseExecutor executor, String url, {required bool isDefault}) {
    final map = rpcNode(url, chainId, isDefault: isDefault).toMap()..[Node.selfIdColumn] = null;
    return executor.insert(Node.tableName, map);
  }

  Future<int> deleteNodes(DatabaseExecutor executor) => executor.delete(
        Node.tableName,
        where: "typeRaw = ? AND chainId = ?",
        whereArgs: [serializeToInt(WalletType.evm), chainId],
      );

  static Future<void> restoreNodesIfNone(int chainId) => db!.transaction((txn) async {
        final nodeRows = await txn.query(
          Node.tableName,
          where: "typeRaw = ? AND chainId = ?",
          whereArgs: [serializeToInt(WalletType.evm), chainId],
          limit: 1,
        );
        if (nodeRows.isNotEmpty) {
          return;
        }

        final networkRows =
            await txn.query(tableName, where: "chainId = ?", whereArgs: [chainId], limit: 1);
        if (networkRows.isEmpty) {
          return;
        }

        await EvmNetwork.fromMap(networkRows.first).replaceNodes(txn);
      });

  static Node rpcNode(String url, int chainId, {bool isDefault = false}) {
    final uri = Uri.parse(url);

    return Node(
      uri: uri.authority,
      path: uri.hasQuery ? "${uri.path}?${uri.query}" : uri.path,
      useSSL: uri.scheme == "https",
      type: WalletType.evm,
      chainId: chainId,
      isDefault: isDefault,
      isEnabledForAutoSwitching: true,
    );
  }

  static Future<List<EvmNetwork>> getAll() async =>
      (await db!.query(tableName, orderBy: "enabledAt")).map(EvmNetwork.fromMap).toList();

  static Future<EvmNetwork?> get(int chainId) async {
    final rows = await db!.query(tableName, where: "chainId = ?", whereArgs: [chainId], limit: 1);
    return rows.isEmpty ? null : EvmNetwork.fromMap(rows.first);
  }
}

class AddedNetworkCurrency extends CryptoCurrency {
  AddedNetworkCurrency(this.network)
      : super(
          title: network.symbol,
          tag: network.tag,
          name: "evm${network.chainId}",
          raw: EvmNativeCurrencies.addedNetworkRaw(network.chainId),
          decimals: network.decimals,
        );

  static AddedNetworkCurrency? of(CryptoCurrency? currency) =>
      currency is AddedNetworkCurrency ? currency : null;

  static AddedNetworkCurrency? tryFromChainId(int? chainId) =>
      chainId == null ? null : of(EvmNativeCurrencies.getNativeCurrencyByChainId(chainId));

  EvmNetwork network;

  int get chainId => network.chainId;

  bool get isManual => network.isManual;

  @override
  String get fullName => network.name;

  @override
  String? get iconPath => network.iconUrl;

  @override
  String? get chainIconPath => network.iconUrl?.isNotEmpty == true ? network.iconUrl : null;
}
