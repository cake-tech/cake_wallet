import 'package:bitbox_flutter/usb/bitbox_device.dart' as bitbox;
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;

abstract class HardwareWalletDevice {
  String get name;

  HardwareWalletDeviceType get type;

  HardwareWalletConnectionType get connectionType;
}

class LedgerHardwareWalletDevice extends HardwareWalletDevice {
  final ledger.LedgerDevice device;

  LedgerHardwareWalletDevice(this.device);

  @override
  String get name => device.name;

  @override
  HardwareWalletDeviceType get type => device.deviceInfo.toGeneric();

  @override
  HardwareWalletConnectionType get connectionType => device.connectionType.toGeneric();
}

class BitboxHardwareWalletDevice extends HardwareWalletDevice {
  final bitbox.BitboxDevice device;

  BitboxHardwareWalletDevice(this.device);

  @override
  String get name => device.productName;

  @override
  HardwareWalletDeviceType get type => name.contains("BitBox02 Nova")
      ? HardwareWalletDeviceType.BitBox02Nova
      : HardwareWalletDeviceType.BitBox02;

  @override
  HardwareWalletConnectionType get connectionType => HardwareWalletConnectionType.usb;
}

enum HardwareWalletDeviceType {
  ledgerBlue,
  ledgerNanoS,
  ledgerNanoX,
  ledgerNanoSPlus,
  ledgerStax,
  ledgerFlex,
  BitBox02,
  BitBox02Nova;
}

enum HardwareWalletConnectionType {
  usb,
  ble,
  nfc,
  qr;
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
