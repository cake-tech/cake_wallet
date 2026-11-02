import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart" as sdk;

class LedgerViewModelDependencies {
  const LedgerViewModelDependencies({
    required this.currentWallet,
    required this.supportsHardwareWallets,
    required this.getHardwareWalletService,
    required this.initWallet,
    required this.clearTronService,
    required this.onMoneroDisconnected,
    this.deviceStateChanges,
    this.connectDevice,
  });

  final WalletBase? Function() currentWallet;
  final bool supportsHardwareWallets;
  final HardwareWalletService Function(WalletType, sdk.LedgerConnection) getHardwareWalletService;
  final Future<void> Function(WalletBase, sdk.LedgerConnection) initWallet;
  final void Function(WalletBase) clearTronService;
  final void Function(bool) onMoneroDisconnected;
  final Stream<sdk.BleConnectionState> Function(LedgerHardwareWalletDevice)? deviceStateChanges;
  final Future<sdk.LedgerConnection> Function(LedgerHardwareWalletDevice)? connectDevice;
}
