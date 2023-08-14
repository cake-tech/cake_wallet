import 'dart:async';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

part 'wallet_info.g.dart';

@HiveType(typeId: WalletInfo.typeId)
class WalletInfo extends HiveObject {
  WalletInfo(this.id, this.name, this.type, this.isRecovery, this.restoreHeight,
      this.timestamp, this.dirPath, this.path, this.address, this.yatEid,
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

  static const typeId = WALLET_INFO_TYPE_ID;
  static const boxName = 'WalletInfo';

  @HiveField(0, defaultValue: '')
  String id;

  @HiveField(1, defaultValue: '')
  String name;

  @HiveField(2)
  WalletType type;

  @HiveField(3, defaultValue: false)
  bool isRecovery;

  @HiveField(4, defaultValue: 0)
  int restoreHeight;

  @HiveField(5, defaultValue: 0)
  int timestamp;

  @HiveField(6, defaultValue: '')
  String dirPath;

  @HiveField(7, defaultValue: '')
  String path;

  @HiveField(8, defaultValue: '')
  String address;

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
