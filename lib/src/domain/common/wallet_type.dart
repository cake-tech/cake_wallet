import 'package:hive/hive.dart';

part 'wallet_type.g.dart';

@HiveType()
enum WalletType {
  @HiveField(0)
  monero,

  @HiveField(1)
  none
}

int serializeToInt(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 0;
    default:
      return -1;
  }
}

WalletType deserializeToInt(int raw) {
  switch (raw) {
    case 0:
      return WalletType.monero;
    default:
      return null;
  }
}

String walletTypeToString(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 'Monero';
    default:
      return '';
  }
}