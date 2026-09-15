import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

abstract class HardwareWalletViewModel {
  HardwareWalletType get hardwareWalletType;
  bool get isBleEnabled;
  bool get hasBluetooth;
  bool get isConnecting;

  bool isConnected(WalletType type);

  Future<void> updateBleState();

  Stream<HardwareWalletDevice> scanForBleDevices();

  Future<List<HardwareWalletDevice>> getAllUsbDevices();

  Future<void> stopScanning();

  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type);

  HardwareWalletService getHardwareWalletService(WalletType type);

  Future<void> initWallet(WalletBase wallet);

  /// Called right before a reconnect for an already existing [wallet] so the
  /// view model can restore whatever it needs to rebuild the device session
  /// without asking the user again. No-op by default.
  Future<void> prepareReconnect(WalletBase wallet) async {}

  /// Called once a hardware [wallet] has been created or restored so the view
  /// model can remember the settings the device was set up with. No-op by
  /// default.
  Future<void> rememberWalletSettings(WalletBase wallet) async {}

  String? interpretErrorCode(String error) => null;

  Future<void> close() async {}
}
