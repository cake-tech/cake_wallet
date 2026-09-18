import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/utils/print_verbose.dart";
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

  /// Devices that already hold a live connection with this view model. A
  /// connected BLE peripheral does not advertise, so a scan will not find it;
  /// the connect page lists these up front so the user can proceed with it.
  Future<List<HardwareWalletDevice>> getConnectedDevices() async => [];

  Future<void> stopScanning();

  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type);

  /// Called instead of [connectDevice] when a new wallet is being restored on a
  /// device that is already connected. Gives the view model a chance to ask for
  /// per-wallet session settings (e.g. a passphrase) and rebind the session.
  /// Returns whether the device is ready for the new wallet. Defaults to
  /// "already ready".
  Future<bool> prepareNewWalletSession(WalletType type) async => true;

  HardwareWalletService getHardwareWalletService(WalletType type);

  Future<void> initWallet(WalletBase wallet);

  /// [initWallet] for flows a user just started (send, swap, buy, resync):
  /// false when the device session could not be bound to [wallet], in which
  /// case the flow must stop. The user has already been shown why, unless
  /// they cancelled the prompt themselves, so callers need no message of
  /// their own. Any other failure still propagates.
  Future<bool> tryInitWallet(WalletBase wallet) async {
    try {
      await initWallet(wallet);
      return true;
    } on TrezorSessionMismatchException catch (e) {
      printV(e);
      return false;
    }
  }

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

/// The live Trezor session could not be bound to the wallet about to use it:
/// the user exited the pairing sheet, or the device does not derive this
/// wallet's keys with the passphrase it was given.
class TrezorSessionMismatchException implements Exception {
  TrezorSessionMismatchException(this.walletName, {this.cancelled = false});

  final String walletName;

  /// True when the session could not be bound because the user exited the
  /// pairing sheet, rather than because the device rejected or mismatched.
  final bool cancelled;

  @override
  String toString() => S.current.trezor_error_session_mismatch;
}
