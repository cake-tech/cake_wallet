import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/unspent_comparable_mixin.dart';
import 'package:hive/hive.dart';

part 'unspent_coins_info.g.dart';

@HiveType(typeId: UnspentCoinsInfo.typeId)
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

  @HiveField(0, defaultValue: '')
  String walletId;

  @HiveField(1, defaultValue: '')
  String hash;

  @HiveField(2, defaultValue: false)
  bool isFrozen;

  @HiveField(3, defaultValue: false)
  bool isSending;

  @HiveField(4)
  String? noteRaw;

  @HiveField(5, defaultValue: '')
  String address;

  @HiveField(6, defaultValue: 0)
  int value;

  @HiveField(7, defaultValue: 0)
  int vout;

  @HiveField(8, defaultValue: null)
  String? keyImage;

  @HiveField(9, defaultValue: false)
  bool isChange;

  @HiveField(10, defaultValue: 0)
  int accountIndex;

  @HiveField(11, defaultValue: false)
  bool? isSilentPayment;

  String get note => noteRaw ?? '';

  set note(String value) => noteRaw = value;
}
