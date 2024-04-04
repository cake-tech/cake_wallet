import 'package:cw_core/wallet_type.dart';

enum DeviceConnectionType {
  usb,
  ble;

  static List<DeviceConnectionType> supportedConnectionTypes(WalletType walletType) {
    switch (walletType) {
      case WalletType.bitcoin:
      case WalletType.ethereum:
      case WalletType.polygon:
        return [DeviceConnectionType.ble, DeviceConnectionType.usb];
      default:
        return [];
    }
  }

  String get iconString {
    switch (this) {
      case ble:
        return 'assets/images/bluetooth.png';
      case usb:
        return 'assets/images/usb.png';
    }
  }
}
