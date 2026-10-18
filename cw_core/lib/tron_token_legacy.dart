import "package:cw_core/cake_hive.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/hive_type_ids.dart";
import "package:cw_core/tron_token.dart" as tron_new;
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:hive/hive.dart";
import "package:sqflite/sqflite.dart";

part "tron_token_legacy.part.dart";

Future<void> performTronTokenHiveMigration() async {
  try {
    if (!CakeHive.isAdapterRegistered(TronToken.typeId)) {
      CakeHive.registerAdapter(TronTokenAdapter());
    }

    final wallets = await WalletInfo.getAll();
    await TronToken.migrateAllToSqlite(wallets);
  } catch (e) {
    printV("Error performing TronToken Hive migration: $e, continuing anyway");
  }
}

// @HiveType(typeId: TronToken.typeId)
class TronToken extends HiveObject {
  TronToken({
    required this.name,
    required this.symbol,
    required this.contractAddress,
    required this.decimal,
    bool enabled = true,
    this.iconPath,
    this.tag = "TRX",
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
  final String? iconPath;

  // @HiveField(6)
  final String? tag;

  // @HiveField(7, defaultValue: false)
  final bool isPotentialScam;

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  static const typeId = TRON_TOKEN_TYPE_ID;
  static const boxName = "TronTokens";

  static Future<void> migrateAllToSqlite(List<WalletInfo> wallets) async {
    final sanitizedToRawNames = <String, Set<String>>{};
    for (final wallet in wallets) {
      if (wallet.type != WalletType.tron) {
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

        final box = await CakeHive.openBox<TronToken>(tokenBoxName);

        for (final key in box.keys.toList()) {
          final token = box.get(key);
          if (token == null) {
            continue;
          }

          for (final rawName in entry.value) {
            await token.migrateToSqlite(walletName: rawName);
          }
          await box.delete(key);
        }

        await box.deleteFromDisk();
      } catch (e) {
        printV("Error migrating tron token box $tokenBoxName: $e, continuing anyway");
      }
    }
  }

  Future<void> migrateToSqlite({required String walletName}) async {
    final row = tron_new.TronToken(
      name: name,
      symbol: symbol,
      contractAddress: contractAddress,
      decimal: decimal,
      enabled: _enabled,
      iconPath: iconPath,
      tag: tag,
      isPotentialScam: isPotentialScam,
      walletName: walletName,
    ).toMap();
    row[tron_new.TronToken.selfIdColumn] = null;

    await db!.insert(
      tron_new.TronToken.tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
