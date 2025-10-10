import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

enum DeviceConnectionType {
  usb,
  ble;

  static List<DeviceConnectionType> supportedConnectionTypes(
      WalletType walletType, HardwareWalletType hardwareType,
      [bool isIOS = false]) {
    bool isSupported = false;
    switch (hardwareType) {
      case HardwareWalletType.bitbox:
        isSupported = [
          WalletType.bitcoin,
          WalletType.litecoin,
          WalletType.ethereum,
          WalletType.polygon
        ].contains(walletType);
        break;
      case HardwareWalletType.ledger:
        isSupported = [
          WalletType.monero,
          WalletType.bitcoin,
          WalletType.litecoin,
          WalletType.ethereum,
          WalletType.polygon
        ].contains(walletType);
        break;
      case HardwareWalletType.trezor:
        isSupported = [
          // WalletType.monero,
          WalletType.bitcoin,
          WalletType.litecoin,
          WalletType.ethereum,
          WalletType.polygon,
        ].contains(walletType);
        break;
    }

    return isSupported
        ? (isIOS
            ? [DeviceConnectionType.ble]
            : [DeviceConnectionType.ble, DeviceConnectionType.usb])
        : [];
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
