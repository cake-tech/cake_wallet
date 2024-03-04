import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cw_core/hardware/cake_ble_connection_manager.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LedgerViewModel {
  final Ledger ledger = Ledger(
    options: LedgerOptions(),
    bleConnectionManager: CakeBleConnectionManager(
      options: LedgerOptions(
        scanMode: ScanMode.balanced,
        maxScanDuration: const Duration(minutes: 5),
      ),
      onPermissionRequest: (_) async {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();

        return statuses.values.where((status) => status.isDenied).isEmpty;
      },
    ),
  );

  Future<void> connectLedger(LedgerDevice device) async => await ledger.connect(device);

  bool get isConnected => ledger.devices.isNotEmpty;

  LedgerDevice get device => ledger.devices.first;

  void setLedger(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.ethereum:
        return ethereum!.setLedger(wallet, ledger);
      case WalletType.polygon:
        return polygon!.setLedger(wallet, ledger);
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }
  }

}
