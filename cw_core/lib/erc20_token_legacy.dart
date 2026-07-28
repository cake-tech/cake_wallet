import "package:cw_core/cake_hive.dart";
import "package:cw_core/erc20_token.dart" as erc20_new;
import "package:cw_core/hive_type_ids.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:hive/hive.dart";

part "erc20_token_legacy.part.dart";

Future<void> performErc20TokenHiveMigration() async {
  try {
    if (!CakeHive.isAdapterRegistered(Erc20Token.typeId)) {
      CakeHive.registerAdapter(Erc20TokenAdapter());
    }

    final wallets = await WalletInfo.getAll();
    await Erc20Token.migrateAllToSqlite(wallets);
  } catch (e) {
    printV("Error performing Erc20Token Hive migration: $e, continuing anyway");
  }
}

// @HiveType(typeId: Erc20Token.typeId)
class Erc20Token extends HiveObject {
  Erc20Token({
    required this.name,
    required this.symbol,
    required this.contractAddress,
    required this.decimal,
    bool enabled = true,
    this.iconPath,
    this.tag,
    this.isPotentialScam = false,
  }) : _enabled = enabled;
  // @HiveField(0)
  final String name;
  // @HiveField(1)
  final String symbol;
  // @HiveField(2)
  final String contractAddress;
  // @HiveField(3)
  final int decimal;
  // @HiveField(4, defaultValue: true)
  bool _enabled;
  // @HiveField(5)
  String? iconPath;
  // @HiveField(6)
  final String? tag;
  // @HiveField(7, defaultValue: false)
  bool isPotentialScam;

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  static const typeId = ERC20_TOKEN_TYPE_ID;
  static const boxName = "Erc20Tokens";
  static const ethereumBoxName = "EthereumErc20Tokens";
  static const polygonBoxName = "PolygonErc20Tokens";
  static const baseBoxName = "BaseErc20Tokens";
  static const arbitrumBoxName = "ArbitrumErc20Tokens";
  static const bscBoxName = "BscErc20Tokens";

  static const chainIdToBoxSuffix = {
    1: ethereumBoxName,
    137: polygonBoxName,
    8453: baseBoxName,
    42161: arbitrumBoxName,
    56: bscBoxName,
  };

  static const evmWalletTypes = [
    WalletType.ethereum,
    WalletType.polygon,
    WalletType.base,
    WalletType.arbitrum,
    WalletType.bsc,
  ];

  static Future<void> migrateAllToSqlite(List<WalletInfo> wallets) async {
    await _migrateLegacyGlobalBox(wallets);

    final sanitizedToRawNames = <String, Set<String>>{};
    for (final wallet in wallets) {
      if (!evmWalletTypes.contains(wallet.type)) {
        continue;
      }

      sanitizedToRawNames
          .putIfAbsent(wallet.name.replaceAll(" ", "_"), () => <String>{})
          .add(wallet.name);
    }

    for (final entry in sanitizedToRawNames.entries) {
      for (final chainEntry in chainIdToBoxSuffix.entries) {
        final tokenBoxName = "${entry.key}_${chainEntry.value}";
        try {
          if (!await CakeHive.boxExists(tokenBoxName)) {
            continue;
          }

          final box = await CakeHive.openBox<Erc20Token>(tokenBoxName);
          final merged = _mergeByLowercaseContract(box.values.toList());

          for (final rawName in entry.value) {
            for (final token in merged) {
              await token.migrateToSqlite(walletName: rawName, chainId: chainEntry.key);
            }
          }

          await box.clear();
          await box.deleteFromDisk();
        } catch (e) {
          printV("Error migrating erc20 token box $tokenBoxName: $e, continuing anyway");
        }
      }
    }
  }

  static Future<void> _migrateLegacyGlobalBox(List<WalletInfo> wallets) async {
    try {
      if (!await CakeHive.boxExists(boxName)) {
        return;
      }

      if (!wallets.any((wallet) => wallet.type == WalletType.ethereum)) {
        return;
      }

      final box = await CakeHive.openBox<Erc20Token>(boxName);
      final merged = _mergeByLowercaseContract(box.values.toList());

      for (final wallet in wallets) {
        if (wallet.type != WalletType.ethereum) {
          continue;
        }

        for (final token in merged) {
          await token.migrateToSqlite(walletName: wallet.name, chainId: 1);
        }
      }

      await box.clear();
      await box.deleteFromDisk();
    } catch (e) {
      printV("Error migrating legacy global erc20 token box: $e, continuing anyway");
    }
  }

  static List<Erc20Token> _mergeByLowercaseContract(List<Erc20Token> tokens) {
    final merged = <String, Erc20Token>{};

    for (final token in tokens) {
      final lowerKey = token.contractAddress.toLowerCase();
      final existing = merged[lowerKey];

      if (existing == null) {
        merged[lowerKey] = token;
        continue;
      }

      merged[lowerKey] = Erc20Token(
        name: token.name,
        symbol: token.symbol,
        contractAddress: lowerKey,
        decimal: token.decimal,
        enabled: token.enabled || existing.enabled,
        iconPath: (token.iconPath?.isNotEmpty ?? false) ? token.iconPath : existing.iconPath,
        tag: token.tag ?? existing.tag,
        isPotentialScam: token.isPotentialScam || existing.isPotentialScam,
      );
    }

    return merged.values.toList();
  }

  Future<void> migrateToSqlite({required String walletName, required int chainId}) async {
    final newToken = erc20_new.Erc20Token(
      name: name,
      symbol: symbol,
      contractAddress: contractAddress,
      decimal: decimal,
      enabled: _enabled,
      iconPath: iconPath,
      tag: tag,
      isPotentialScam: isPotentialScam,
      walletName: walletName,
      chainId: chainId,
    );
    await newToken.save();
  }
}
