import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/coin_control/coin_notes_store.dart';
import 'package:cw_core/coin_control/frozen_coins_store.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/unspent_comparable_mixin.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

part 'unspent_coins_info.part.dart';

Future<void> performUnspentCoinsInfoHiveMigration() async {
  try {
    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }

    if (!await CakeHive.boxExists(UnspentCoinsInfo.boxName)) {
      return;
    }

    final wallets = await WalletInfo.getAll();
    await UnspentCoinsInfo.migrateAllToSqlite(wallets);
  } catch (e) {
    printV("Error performing UnspentCoinsInfo Hive migration: $e, continuing anyway");
  }
}

// @HiveType(typeId: UnspentCoinsInfo.typeId)
class UnspentCoinsInfo extends HiveObject with UnspentComparable {
  UnspentCoinsInfo({
    required this.walletId,
    required this.hash,
    required this.isFrozen,
    required this.isSending,
    required this.noteRaw,
    required this.address,
    required this.vout,
    required this.value,
    this.keyImage = null,
    this.isChange = false,
    this.accountIndex = 0,
    this.isSilentPayment = false,
  });

  static const typeId = UNSPENT_COINS_INFO_TYPE_ID;
  static const boxName = 'Unspent';
  static const boxKey = 'unspentBoxKey';

  // @HiveField(0, defaultValue: '')
  String walletId;

  // @HiveField(1, defaultValue: '')
  String hash;

  // @HiveField(2, defaultValue: false)
  bool isFrozen;

  // @HiveField(3, defaultValue: false)
  bool isSending;

  // @HiveField(4)
  String? noteRaw;

  // @HiveField(5, defaultValue: '')
  String address;

  // @HiveField(6, defaultValue: 0)
  int value;

  // @HiveField(7, defaultValue: 0)
  int vout;

  // @HiveField(8, defaultValue: null)
  String? keyImage;

  // @HiveField(9, defaultValue: false)
  bool isChange;

  // @HiveField(10, defaultValue: 0)
  int accountIndex;

  // @HiveField(11, defaultValue: false)
  bool? isSilentPayment;

  String get note => noteRaw ?? '';

  set note(String value) => noteRaw = value;

  static Future<void> migrateAllToSqlite(List<WalletInfo> wallets) async {
    final box = await CakeHive.openBox<UnspentCoinsInfo>(boxName);

    for (final record in box.values.toList()) {
      final type = wallets
          .cast<WalletInfo?>()
          .firstWhere((item) => item!.id == record.walletId, orElse: () => null)
          ?.type;

      if (type == null) {
        return;
      }

      try {
        await record.migrateToSqlite(type);
      } catch (e) {
        printV("Error migrating unspent record ${record.walletId}: $e, continuing anyway");
      }
    }
  }

  Future<void> migrateToSqlite(WalletType walletType) async {
    final id = _outputId(walletType);

    if (note.isNotEmpty) {
      await CoinNotesStore.instance.save(walletId, id, note);
    }
    if (walletType != WalletType.monero) {
      await FrozenCoinsStore.instance.setFrozen(walletId, id, isFrozen);
    }

  }


  String _outputId(WalletType walletType) {
    if (keyImage != null && keyImage!.isNotEmpty) {
      return keyImage!;
    }

    if (walletType == WalletType.litecoin && _isMwebAddress(address)) {
      return hash;
    }

    return "$hash:$vout";
  }

  static bool _isMwebAddress(String address) =>
      address.startsWith("ltcmweb1") || address.startsWith("tmweb1");
}
