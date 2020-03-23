import 'package:hive/hive.dart';

part 'wallet_type.g.dart';

@HiveType()
enum WalletType {
  @HiveField(0)
  monero,

  @HiveField(1)
  bitcoin,

  @HiveField(2)
  none
}

final walletTypesList = [
  walletTypeToString(WalletType.monero),
  walletTypeToString(WalletType.bitcoin)
];

int serializeToInt(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 0;
    case WalletType.bitcoin:
      return 1;
    default:
      return -1;
  }
}

WalletType deserializeToInt(int raw) {
  switch (raw) {
    case 0:
      return WalletType.monero;
    case 1:
      return WalletType.bitcoin;
    default:
      return null;
  }
}

String walletTypeToString(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 'Monero';
    case WalletType.bitcoin:
      return 'Bitcoin';
    default:
      return '';
  }
}