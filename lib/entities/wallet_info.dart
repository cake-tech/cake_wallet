import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

part 'wallet_info.g.dart';

@HiveType(typeId: WalletInfo.typeId)
class WalletInfo extends HiveObject {
  WalletInfo(this.id, this.name, this.type, this.isRecovery, this.restoreHeight,
      this.timestamp, this.dirPath, this.path, this.address);

  factory WalletInfo.external(
      {@required String id,
      @required String name,
      @required WalletType type,
      @required bool isRecovery,
      @required int restoreHeight,
      @required DateTime date,
      @required String dirPath,
      @required String path,
      @required String address}) {
    return WalletInfo(id, name, type, isRecovery, restoreHeight,
        date.millisecondsSinceEpoch ?? 0, dirPath, path, address);
  }

  static const typeId = 4;
  static const boxName = 'WalletInfo';

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  WalletType type;

  @HiveField(3)
  bool isRecovery;

  @HiveField(4)
  int restoreHeight;

  @HiveField(5)
  int timestamp;

  @HiveField(6)
  String dirPath;

  @HiveField(7)
  String path;

  @HiveField(8)
  String address;

  @HiveField(10)
  Map<String, String> addresses;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
