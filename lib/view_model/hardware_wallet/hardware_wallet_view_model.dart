import 'package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

abstract class HardwareWalletViewModel {
  bool get isConnected;
  bool get isBleEnabled;
  bool get hasBluetooth;

  Future<void> updateBleState();

  Stream<HardwareWalletDevice> scanForBleDevices();

  Future<List<HardwareWalletDevice>> getAllUsbDevices();

  Future<void> stopScanning();

  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type);

  HardwareWalletService getHardwareWalletService(WalletType type);

  void initWallet(WalletBase wallet);

  String? interpretErrorCode(String error) => null;
}

