import "package:cw_core/cake_hive.dart";
import "package:cw_core/hive_type_ids.dart";
import "package:cw_core/spl_token.dart" as spl_new;
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:hive/hive.dart";

part "spl_token_legacy.part.dart";

Future<void> performSplTokenHiveMigration() async {
  try {
    if (!CakeHive.isAdapterRegistered(SPLToken.typeId)) {
      CakeHive.registerAdapter(SPLTokenAdapter());
    }

    final wallets = await WalletInfo.getAll();
    await SPLToken.migrateAllToSqlite(wallets);
  } catch (e) {
    printV("Error performing SPLToken Hive migration: $e, continuing anyway");
  }
}

// @HiveType(typeId: SPLToken.typeId)
class SPLToken extends HiveObject {

  SPLToken({
    required this.name,
    required this.symbol,
    required this.mintAddress,
    required this.decimal,
    required this.mint,
    this.iconPath,
    this.tag = "SOL",
    bool enabled = true,
    this.isPotentialScam = false,
  }) : _enabled = enabled;
  // @HiveField(0)
  final String name;

  // @HiveField(1)
  final String symbol;

  // @HiveField(2)
  final String mintAddress;

  // @HiveField(3)
  final int decimal;

  // @HiveField(4, defaultValue: true)
  bool _enabled;

  // @HiveField(5)
  final String mint;

  // @HiveField(6)
  final String? iconPath;

  // @HiveField(7)
  final String? tag;

  // @HiveField(8, defaultValue: false)
  bool isPotentialScam;

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  static const typeId = SPL_TOKEN_TYPE_ID;
  static const boxName = "SPLTokens";

  static Future<void> migrateAllToSqlite(List<WalletInfo> wallets) async {
    final sanitizedToRawNames = <String, Set<String>>{};
    for (final wallet in wallets) {
      if (wallet.type != WalletType.solana) {
        continue;
      }

      sanitizedToRawNames
          .putIfAbsent(wallet.name.replaceAll(" ", "_"), () => <String>{})
          .add(wallet.name);
    }

    for (final entry in sanitizedToRawNames.entries) {
      final tokenBoxName = "${entry.key}_$boxName";
      try {
        if (!await CakeHive.boxExists(tokenBoxName)) {
          continue;
        }

        final box = await CakeHive.openBox<SPLToken>(tokenBoxName);
        final tokens = box.values.toList();

        for (final rawName in entry.value) {
          for (final token in tokens) {
            await token.migrateToSqlite(walletName: rawName);
          }
        }

        await box.clear();
        await box.deleteFromDisk();
      } catch (e) {
        printV("Error migrating spl token box $tokenBoxName: $e, continuing anyway");
      }
    }
  }

  Future<void> migrateToSqlite({required String walletName}) async {
    final newToken = spl_new.SPLToken(
      name: name,
      symbol: symbol,
      mintAddress: mintAddress,
      decimal: decimal,
      mint: mint,
      enabled: _enabled,
      iconPath: iconPath,
      tag: tag,
      isPotentialScam: isPotentialScam,
      walletName: walletName,
    );
    await newToken.save();
  }
}
