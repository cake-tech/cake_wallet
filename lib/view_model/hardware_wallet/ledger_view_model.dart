import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as sdk;
import 'package:permission_handler/permission_handler.dart';

class LedgerViewModel {
  // late final Ledger ledger;
  late final sdk.LedgerInterface ledgerPlusBle;

  bool get _doesSupportHardwareWallets {
    if (!DeviceInfo.instance.isMobile) {
      return false;
    }

    if (isMoneroOnly) {
      return DeviceConnectionType.supportedConnectionTypes(
              WalletType.monero, Platform.isIOS)
          .isNotEmpty;
    }

    return true;
  }

  LedgerViewModel() {
    if (_doesSupportHardwareWallets) {
      ledgerPlusBle = sdk.LedgerInterface.ble(onPermissionRequest: (_) async {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();

        return statuses.values.where((status) => status.isDenied).isEmpty;
      });
    }
  }

  Stream<sdk.LedgerDevice> scanForDevices() => ledgerPlusBle.scan();

  Future<void> connectLedger(sdk.LedgerDevice device) async {
    if (isConnected) await _connection!.disconnect();
    _connection = await ledgerPlusBle.connect(device);
    print("Connected");
  }

  sdk.LedgerConnection? _connection;

  bool get isConnected => _connection != null && !(_connection!.isDisconnected);

  sdk.LedgerConnection get connection => _connection!;

  void setLedger(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        return bitcoin!.setLedgerConnection(wallet, connection);
      case WalletType.ethereum:
        return ethereum!.setLedgerConnection(wallet, connection);
      case WalletType.polygon:
        return polygon!.setLedgerConnection(wallet, connection);
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }
  }

  String? interpretErrorCode(String errorCode) {
    switch (errorCode) {
      case "6985":
        return S.current.ledger_error_tx_rejected_by_user;
      case "5515":
        return S.current.ledger_error_device_locked;
      case "6d02": // UNKNOWN_APDU
      case "6511":
      case "6e00":
        return S.current.ledger_error_wrong_app;
      default:
        return null;
    }
  }
}
