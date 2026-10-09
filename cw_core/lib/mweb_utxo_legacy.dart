import "package:cw_core/cake_hive.dart";
import "package:cw_core/hive_type_ids.dart";
import "package:cw_core/mweb_utxo.dart" as mweb_new;
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:hive/hive.dart";

part 'mweb_utxo_legacy.part.dart';

Future<void> performMwebUtxoHiveMigration() async {
  try {
    if (!CakeHive.isAdapterRegistered(MwebUtxo.typeId)) {
      CakeHive.registerAdapter(MwebUtxoAdapter());
    }

    await MwebUtxo.migrateAllToSqlite(await WalletInfo.getAll());
  } catch (e) {
    printV("Error performing MwebUtxo Hive migration: $e");
  }
}

// @HiveType(typeId: MWEB_UTXO_TYPE_ID)
class MwebUtxo extends HiveObject {
  MwebUtxo({
    required this.height,
    required this.value,
    required this.address,
    required this.outputId,
    required this.blockTime,
    this.spent = false,
  });

  static const typeId = MWEB_UTXO_TYPE_ID;
  static const boxName = 'MwebUtxo';

  static Future<void> migrateAllToSqlite(List<WalletInfo> wallets) async {
    for (final wallet in wallets) {
      if (wallet.type != WalletType.litecoin) {
        continue;
      }

      final legacyBoxName = "${wallet.name.replaceAll(" ", "_")}_$boxName";

      try {
        if (!await CakeHive.boxExists(legacyBoxName)) {
          continue;
        }

        final box = await CakeHive.openBox<MwebUtxo>(legacyBoxName);

        for (final utxo in box.values) {
          await mweb_new.MwebUtxo(
            walletInfoId: wallet.internalId,
            height: utxo.height,
            value: utxo.value,
            address: utxo.address,
            outputId: utxo.outputId,
            blockTime: utxo.blockTime,
            spent: utxo.spent,
          ).save();
        }

        await box.deleteFromDisk();
      } catch (e) {
        printV("Error migrating mweb utxo box $legacyBoxName: $e");
      }
    }
  }

  // @HiveField(0)
  int height;

  // @HiveField(1)
  int value;

  // @HiveField(2)
  String address;

  // @HiveField(3)
  String outputId;

  // @HiveField(4)
  int blockTime;

  // @HiveField(5, defaultValue: false)
  bool spent;
}
