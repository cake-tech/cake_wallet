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
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LedgerViewModel {
  late final Ledger ledger;

  bool get _doesSupportHardwareWallets {
    if (!DeviceInfo.instance.isMobile) {
      return false;
    }

    if (isMoneroOnly) {
      return DeviceConnectionType.supportedConnectionTypes(WalletType.monero, Platform.isIOS)
          .isNotEmpty;
    }

    return true;
  }

  LedgerViewModel() {
    if (_doesSupportHardwareWallets) {
      ledger = Ledger(
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
      );
    }
  }

  Future<void> connectLedger(LedgerDevice device) async {
    await ledger.connect(device);

    if (device.connectionType == ConnectionType.usb) _device = device;
  }

  LedgerDevice? _device;

  bool get isConnected => ledger.devices.isNotEmpty || _device != null;

  LedgerDevice get device => _device ?? ledger.devices.first;

  void setLedger(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return bitcoin!.setLedger(wallet, ledger, device);
      case WalletType.ethereum:
        return ethereum!.setLedger(wallet, ledger, device);
      case WalletType.polygon:
        return polygon!.setLedger(wallet, ledger, device);
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
