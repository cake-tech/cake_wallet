import "package:bitbox_flutter/bitbox_flutter.dart" as bitbox;
import "package:ledger_flutter_plus/ledger_flutter_plus.dart" as ledger;
import "package:trezor_flutter/trezor_flutter.dart" as trezor;

abstract class HardwareWalletDevice {
  String get name;

  HardwareWalletDeviceType get type;

  HardwareWalletConnectionType get connectionType;
}

class LedgerHardwareWalletDevice extends HardwareWalletDevice {
  LedgerHardwareWalletDevice(this.device);

  final ledger.LedgerDevice device;

  @override
  String get name => device.name;

  @override
  HardwareWalletDeviceType get type => device.deviceInfo.toGeneric();

  @override
  HardwareWalletConnectionType get connectionType => device.connectionType.toGeneric();
}

class BitboxHardwareWalletDevice extends HardwareWalletDevice {
  BitboxHardwareWalletDevice(this.device);

  final bitbox.BitboxDevice device;

  @override
  String get name => device.productName;

  @override
  HardwareWalletDeviceType get type => name.contains("BitBox02 Nova")
      ? HardwareWalletDeviceType.bitBox02Nova
      : HardwareWalletDeviceType.bitBox02;

  @override
  HardwareWalletConnectionType get connectionType =>
      device.isUsb ? HardwareWalletConnectionType.usb : HardwareWalletConnectionType.ble;
}

class TrezorHardwareWalletDevice extends HardwareWalletDevice {
  TrezorHardwareWalletDevice(this.device);

  final trezor.TrezorDevice device;

  @override
  String get name => device.name;

  @override
  HardwareWalletDeviceType get type => device.deviceInfo.toGeneric();

  @override
  HardwareWalletConnectionType get connectionType => device.connectionType.toGeneric();
}

enum HardwareWalletDeviceType {
  ledgerBlue,
  ledgerNanoS,
  ledgerNanoX,
  ledgerNanoSPlus,
  ledgerNanoGen5,
  ledgerStax,
  ledgerFlex,
  bitBox02,
  bitBox02Nova,
  trezorModelOne,
  trezorModelT,
  trezorSafe3,
  trezorSafe5,
  trezorSafe7;
}

enum HardwareWalletConnectionType {
  usb,
  ble,
  nfc,
  qr;
}

extension LedgerToGenericHardwareWalletDeviceType on ledger.LedgerDeviceType {
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
      case ledger.LedgerDeviceType.nanoGen5:
        return HardwareWalletDeviceType.ledgerNanoGen5;
      case ledger.LedgerDeviceType.stax:
        return HardwareWalletDeviceType.ledgerStax;
      case ledger.LedgerDeviceType.flex:
        return HardwareWalletDeviceType.ledgerFlex;
    }
  }
}

extension TrezorToGenericHardwareWalletDeviceType on trezor.TrezorDeviceType {
  HardwareWalletDeviceType toGeneric() {
    switch (this) {
      case trezor.TrezorDeviceType.modelOne:
        return HardwareWalletDeviceType.trezorModelOne;
      case trezor.TrezorDeviceType.modelT:
        return HardwareWalletDeviceType.trezorModelT;
      case trezor.TrezorDeviceType.safe3:
        return HardwareWalletDeviceType.trezorSafe3;
      case trezor.TrezorDeviceType.safe5:
        return HardwareWalletDeviceType.trezorSafe5;
      case trezor.TrezorDeviceType.safe7:
        return HardwareWalletDeviceType.trezorSafe7;
    }
  }
}

extension LedgerToGenericHardwareWalletConnectionType on ledger.ConnectionType {
  HardwareWalletConnectionType toGeneric() {
    switch (this) {
      case ledger.ConnectionType.usb:
        return HardwareWalletConnectionType.usb;
      case ledger.ConnectionType.ble:
        return HardwareWalletConnectionType.ble;
    }
  }
}

extension TrezorToGenericHardwareWalletConnectionType on trezor.ConnectionType {
  HardwareWalletConnectionType toGeneric() {
    switch (this) {
      case trezor.ConnectionType.usb:
        return HardwareWalletConnectionType.usb;
      case trezor.ConnectionType.ble:
        return HardwareWalletConnectionType.ble;
    }
  }
}
