import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/wallet_type.dart';
import 'dart:async';

part 'wallet_info.g.dart';

@HiveType(typeId: WalletInfo.typeId)
class WalletInfo extends HiveObject {
  WalletInfo(this.idRaw, this.nameRaw, this.type, this.isRecoveryRaw, this.restoreHeightRaw,
      this.timestampRaw, this.dirPathRaw, this.pathRaw, this.addressRaw, this.yatEid,
        this.yatLastUsedAddressRaw, this.showIntroCakePayCard)
      : _yatLastUsedAddressController = StreamController<String>.broadcast();

  factory WalletInfo.external(
      {required String id,
      required String name,
      required WalletType type,
      required bool isRecovery,
      required int restoreHeight,
      required DateTime date,
      required String dirPath,
      required String path,
      required String address,
      bool? showIntroCakePayCard,
      String yatEid ='',
      String yatLastUsedAddressRaw = ''}) {
    return WalletInfo(id, name, type, isRecovery, restoreHeight,
        date.millisecondsSinceEpoch, dirPath, path, address,
        yatEid, yatLastUsedAddressRaw, showIntroCakePayCard);
  }

  static const typeId = 4;
  static const boxName = 'WalletInfo';

  @HiveField(0)
  String? idRaw;

  @HiveField(1)
  String? nameRaw;

  @HiveField(2)
  WalletType type;

  @HiveField(3)
  bool? isRecoveryRaw;

  @HiveField(4)
  int? restoreHeightRaw;

  @HiveField(5)
  int? timestampRaw;

  @HiveField(6)
  String? dirPathRaw;

  @HiveField(7)
  String? pathRaw;

  @HiveField(8)
  String? addressRaw;

  @HiveField(10)
  Map<String, String>? addresses;

  @HiveField(11)
  String? yatEid;

  @HiveField(12)
  String? yatLastUsedAddressRaw;

  @HiveField(13)
  bool? showIntroCakePayCard;

  String get yatLastUsedAddress => yatLastUsedAddressRaw ?? '';

  set yatLastUsedAddress(String address) {
    yatLastUsedAddressRaw = address;
    _yatLastUsedAddressController.add(address);
  }

  String get id => idRaw ?? '';

  set id(String value) => idRaw = value;

  String get name => nameRaw ?? '';

  set name(String value) => nameRaw = value;

  bool get isRecovery => isRecoveryRaw ?? false;

  set isRecovery(bool value) => isRecoveryRaw = value;

  int get restoreHeight => restoreHeightRaw ?? 0;

  set restoreHeight(int value) => restoreHeightRaw = value;

  int get timestamp => timestampRaw ?? 0;

  set timestamp(int value) => timestampRaw = value;

  String get dirPath => dirPathRaw ?? '';

  set dirPath(String value) => dirPathRaw = value;

  String get path => pathRaw ?? '';

  set path(String value) => pathRaw = value;

  String get address => addressRaw ?? '';

  set address(String value) => addressRaw = value;

  String get yatEmojiId => yatEid ?? '';

  bool get isShowIntroCakePayCard {
    if(showIntroCakePayCard == null) {
      return type != WalletType.haven;
    }
    return showIntroCakePayCard!;
  }

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Stream<String> get yatLastUsedAddressStream => _yatLastUsedAddressController.stream;

  StreamController<String> _yatLastUsedAddressController;
}
