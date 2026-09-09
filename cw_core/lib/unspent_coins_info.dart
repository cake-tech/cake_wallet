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

  /// Wallet types whose core module owns frozen state, so it is not migrated.
  ///
  /// Monero persists the flag inside the wallet file, which is where it is read
  /// from now, so a row in the FrozenCoin table would be a second source of
  /// truth for something the wallet already has.
  static const _typesOwningFrozenState = [WalletType.monero, WalletType.wownero];

  static Future<void> migrateAllToSqlite(List<WalletInfo> wallets) async {
    final box = await CakeHive.openBox<UnspentCoinsInfo>(boxName);
    final walletTypes = {for (final wallet in wallets) wallet.id: wallet.type};

    for (final record in box.values.toList()) {
      final type = walletTypes[record.walletId];
      if (type == null) {
        // Left behind by a wallet that has since been deleted.
        continue;
      }

      try {
        await record.migrateToSqlite(type);
      } catch (e) {
        printV("Error migrating unspent record ${record.walletId}: $e, continuing anyway");
      }
    }

    await box.deleteFromDisk();
  }

  Future<void> migrateToSqlite(WalletType walletType) async {
    // This box held a record for every output the wallet had ever seen, so
    // only the ones carrying something the user set are worth a row. The new
    // tables read an absent row as not frozen with no note, which is what all
    // the rest of these amount to.
    final shouldMigrateFrozen = isFrozen && !_typesOwningFrozenState.contains(walletType);
    if (note.isEmpty && !shouldMigrateFrozen) {
      return;
    }

    final id = _outputId(walletType);

    if (note.isNotEmpty) {
      await CoinNotesStore.instance.save(walletId, id, note);
    }

    if (shouldMigrateFrozen) {
      await FrozenCoinsStore.instance.setFrozen(walletId, id, true);
    }

    // isSending is deliberately dropped: the selection is not durable state,
    // and persisting it is what let an unselected output be spent after the
    // sending flow that unselected it had closed.
  }

  /// The id the new tables key on, as the output itself now reports it.
  ///
  /// Reproduced from the record rather than asked of the chain module, because
  /// by the time this runs the record is all that is left -- the outputs it
  /// describes are not fetched during startup.
  String _outputId(WalletType walletType) {
    final image = keyImage;
    if (image != null && image.isNotEmpty) {
      return image;
    }

    // An MWEB output is identified by its hash alone. The vout on these
    // records is an index into the wallet's MWEB address list, which shifts as
    // that list grows, so it was never part of the identity.
    if (walletType == WalletType.litecoin && _isMwebAddress(address)) {
      return hash;
    }

    return "$hash:$vout";
  }

  static bool _isMwebAddress(String address) =>
      address.startsWith("ltcmweb1") || address.startsWith("tmweb1");
}
