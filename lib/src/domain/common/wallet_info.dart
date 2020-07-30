import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:hive/hive.dart';

part 'wallet_info.g.dart';

@HiveType(typeId: 4)
class WalletInfo extends HiveObject {
  WalletInfo(
      {this.id, this.name, this.type, this.isRecovery, this.restoreHeight});

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
}
