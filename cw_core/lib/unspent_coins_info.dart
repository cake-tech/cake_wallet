import 'package:hive/hive.dart';

part 'unspent_coins_info.g.dart';

@HiveType(typeId: UnspentCoinsInfo.typeId)
class UnspentCoinsInfo extends HiveObject {
  UnspentCoinsInfo({
    required this.walletIdRaw,
    required this.hashRaw,
    required this.isFrozenRaw,
    required this.isSendingRaw,
    required this.noteRaw});

  factory UnspentCoinsInfo.create({
    required String walletId,
    required String hash,
    required bool isFrozen,
    required bool isSending,
    required String? note})
    => UnspentCoinsInfo(
      walletIdRaw: walletId,
      hashRaw: hash,
      isFrozenRaw: isFrozen,
      isSendingRaw: isSending,
      noteRaw: note);

  static const typeId = 9;
  static const boxName = 'Unspent';
  static const boxKey = 'unspentBoxKey';

  @HiveField(0)
  String? walletIdRaw;

  @HiveField(1)
  String? hashRaw;

  @HiveField(2)
  bool? isFrozenRaw;

  @HiveField(3)
  bool? isSendingRaw;

  @HiveField(4)
  String? noteRaw;

  String get note => noteRaw ?? '';

  set note(String value) => noteRaw = value;

  String get walletId => walletIdRaw ?? '';
  
  set walletId(String value) => walletIdRaw = value;
  
  String get hash => hashRaw ?? '';
  
  set hash(String value) => hashRaw = value;
  
  bool get isFrozen => isFrozenRaw ?? false;
  
  set isFrozen(bool value) => isFrozenRaw = value;
  
  bool get isSending => isSendingRaw ?? false;

  set isSending(bool value) => isSendingRaw = value;
} 