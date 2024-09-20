import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;

class HardwareWalletDevice {
  final String name;
  final HardwareWalletDeviceType type;
  final HardwareWalletConnectionType connectionType;

  const HardwareWalletDevice({
    required this.name,
    required this.type,
    required this.connectionType,
  });

  factory HardwareWalletDevice.fromLedgerDevice(ledger.LedgerDevice device) =>
      HardwareWalletDevice(
        name: device.name,
        type: device.deviceInfo?.toGeneric() ?? HardwareWalletDeviceType.ledgerNanoX,
        connectionType: device.connectionType.toGeneric(),
      );
}

enum HardwareWalletDeviceType {
  ledgerNanoX,
  ledgerStax,
  ledgerFlex;
}

enum HardwareWalletConnectionType {
  usb,
  ble,
  nfc;
}

extension ToGenericHardwareWalletDeviceType on ledger.LedgerBleDeviceInfo {
  HardwareWalletDeviceType toGeneric() {
    switch (this) {
      case ledger.LedgerBleDeviceInfo.nanoX:
        return HardwareWalletDeviceType.ledgerNanoX;
      case ledger.LedgerBleDeviceInfo.stax:
        return HardwareWalletDeviceType.ledgerStax;
      case ledger.LedgerBleDeviceInfo.flex:
        return HardwareWalletDeviceType.ledgerFlex;
    }
  }
}

extension ToGenericHardwareWalletConnectionType on ledger.ConnectionType {
  HardwareWalletConnectionType toGeneric() {
    switch (this) {
      case ledger.ConnectionType.usb:
        return HardwareWalletConnectionType.usb;
      case ledger.ConnectionType.ble:
        return HardwareWalletConnectionType.ble;
    }
  }
}
