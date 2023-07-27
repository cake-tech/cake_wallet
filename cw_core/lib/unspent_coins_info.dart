import 'package:hive/hive.dart';

part 'unspent_coins_info.g.dart';

@HiveType(typeId: UnspentCoinsInfo.typeId)
class UnspentCoinsInfo extends HiveObject {
  UnspentCoinsInfo({
    required this.walletId,
    required this.hash,
    required this.isFrozen,
    required this.isSending,
    required this.noteRaw,
    required this.address,
    required this.vout,
    required this.value});

  static const typeId = 9;
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

  String get note => noteRaw ?? '';

  set note(String value) => noteRaw = value;
}