import 'package:hive/hive.dart';

part 'unspent_coins_info.g.dart';

@HiveType(typeId: UnspentCoinsInfo.typeId)
class UnspentCoinsInfo extends HiveObject {
  UnspentCoinsInfo({
    this.walletId,
    this.hash,
    this.isFrozen,
    this.isSending,
    this.note});

  static const typeId = 9;
  static const boxName = 'Unspent';
  static const boxKey = 'unspentBoxKey';

  @HiveField(0)
  String? walletId;

  @HiveField(1)
  String? hash;

  @HiveField(2)
  bool? isFrozen;

  @HiveField(3)
  bool? isSending;

  @HiveField(4)
  String? note;
}