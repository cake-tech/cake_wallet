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
        type: device.deviceInfo.toGeneric(),
        connectionType: device.connectionType.toGeneric(),
      );
}

enum HardwareWalletDeviceType {
  ledgerBlue,
  ledgerNanoS,
  ledgerNanoX,
  ledgerNanoSPlus,
  ledgerStax,
  ledgerFlex;
}

enum HardwareWalletConnectionType {
  usb,
  ble,
  nfc;
}

extension ToGenericHardwareWalletDeviceType on ledger.LedgerDeviceType {
  HardwareWalletDeviceType toGeneric() {
    switch (this) {
      case ledger.LedgerDeviceType.blue:
        return HardwareWalletDeviceType.ledgerBlue;
      case ledger.LedgerDeviceType.nanoS:
        return HardwareWalletDeviceType.ledgerNanoS;
      case ledger.LedgerDeviceType.nanoSP:
        return HardwareWalletDeviceType.ledgerNanoSPlus;
      case ledger.LedgerDeviceType.nanoX:
        return HardwareWalletDeviceType.ledgerNanoX;
      case ledger.LedgerDeviceType.stax:
        return HardwareWalletDeviceType.ledgerStax;
      case ledger.LedgerDeviceType.flex:
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
