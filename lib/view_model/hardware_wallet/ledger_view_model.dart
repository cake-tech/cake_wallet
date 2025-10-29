import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as sdk;
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';

part 'ledger_view_model.g.dart';

class LedgerViewModel = LedgerViewModelBase with _$LedgerViewModel;

abstract class LedgerViewModelBase extends HardwareWalletViewModel with Store {
  late final sdk.LedgerInterface ledgerPlusBLE;
  late final sdk.LedgerInterface ledgerPlusUSB;

  bool get _doesSupportHardwareWallets {
    if (isMoneroOnly) {
      return DeviceConnectionType.supportedConnectionTypes(
              WalletType.monero, HardwareWalletType.ledger, Platform.isIOS)
          .isNotEmpty;
    }

    return true;
  }

  LedgerViewModelBase() {
    if (_doesSupportHardwareWallets) {
      reaction((_) => isBleEnabled, (_) {
        if (isBleEnabled) _initBLE();
      });
      updateBleState();

      if (!Platform.isIOS) {
        ledgerPlusUSB = sdk.LedgerInterface.usb();
      }
    }
  }

  @override
  HardwareWalletType get hardwareWalletType => HardwareWalletType.ledger;

  @override
  @observable
  bool isBleEnabled = false;

  @override
  bool get hasBluetooth => true;

  bool _bleIsInitialized = false;

  Future<void> _initBLE() async {
    if (isBleEnabled && !_bleIsInitialized) {
      ledgerPlusBLE = sdk.LedgerInterface.ble(
        onPermissionRequest: (_) async {
          if (Platform.isMacOS) return true;

          Map<Permission, PermissionStatus> statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ].request();

          return statuses.values.where((status) => status.isDenied).isEmpty;
        },
        bleOptions: sdk.BluetoothOptions(maxScanDuration: Duration(minutes: 5)),
      );
      _bleIsInitialized = true;
    }
  }

  @override
  Future<void> updateBleState() async {
    final bleState = await sdk.UniversalBle.getBluetoothAvailabilityState();

    final newState = bleState == sdk.AvailabilityState.poweredOn;

    if (newState != isBleEnabled) isBleEnabled = newState;
  }

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() =>
      ledgerPlusBLE.scan().map((d) => LedgerHardwareWalletDevice(d));

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() => ledgerPlusUSB.devices
      .then((devices) => devices.map((d) => LedgerHardwareWalletDevice(d)).toList());

  @override
  Future<void> stopScanning() async {
    if (_bleIsInitialized) await ledgerPlusBLE.stopScanning();
    if (!Platform.isIOS) await ledgerPlusUSB.stopScanning();
  }

  @override
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    if (!(device is LedgerHardwareWalletDevice)) return false;
    if (_isConnecting) return false;
    _isConnecting = true;
    _connectingWalletType = type;
    if (isConnected) {
      try {
        await _connection!.disconnect().catchError((_) {});
      } catch (_) {}
    }

    final ledger = device.connectionType == HardwareWalletConnectionType.ble
        ? ledgerPlusBLE
        : ledgerPlusUSB;

    if (_connectionChangeSubscription == null) {
      _connectionChangeSubscription = ledger
          .deviceStateChanges
          .listen(_connectionChangeListener);
    }

    try {
      _connection = await ledger.connect(device.device);
      _isConnecting = false;
      return true;
    } catch (e) {
      printV(e);
    }
    _isConnecting = false;
    return false;
  }

  StreamSubscription<sdk.BleConnectionState>? _connectionChangeSubscription;
  sdk.LedgerConnection? _connection;
  bool _isConnecting = false;
  WalletType? _connectingWalletType;

  void _connectionChangeListener(sdk.BleConnectionState event) {
    printV('Ledger Device State Changed: $event');
    if (event == sdk.BleConnectionState.disconnected && !_isConnecting) {
      _connection = null;
      if (_connectingWalletType == WalletType.monero) {
        monero!.resetLedgerConnection();

        Navigator.of(navigatorKey.currentContext!).pushNamed(
          Routes.connectDevices,
          arguments: ConnectDevicePageParams(
            walletType: WalletType.monero,
            hardwareWalletType: HardwareWalletType.ledger,
            allowChangeWallet: true,
            isReconnect: true,
            onConnectDevice: (context, ledgerVM) async {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      }
    }
  }

  @override
  bool get isConnected => _connection != null && !(_connection!.isDisconnected);

  sdk.LedgerConnection get connection => _connection!;

  @override
  void initWallet(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.monero:
        return monero!.setLedgerConnection(wallet, connection);
      case WalletType.bitcoin:
        return bitcoin!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.litecoin:
        return bitcoin!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.ethereum:
        return ethereum!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.polygon:
        return polygon!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }
  }

  @override
  HardwareWalletService getHardwareWalletService(WalletType type) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoin!.getLedgerHardwareWalletService(connection, true);
      case WalletType.litecoin:
        return bitcoin!.getLedgerHardwareWalletService(connection, false);
      case WalletType.ethereum:
        return ethereum!.getLedgerHardwareWalletService(connection);
      case WalletType.polygon:
        return polygon!.getLedgerHardwareWalletService(connection);
      default:
        throw UnimplementedError();
    }
  }


  @override
  String? interpretErrorCode(String error) {
    if (error.contains("Make sure no other program is communicating with the Ledger")) {
      return error;
    }

    var errorRegex = RegExp(r'(?:0x\S*?|[0-9a-f]{4})(?= )').firstMatch(error.toString());

    String errorCode = errorRegex?.group(0).toString().replaceAll("0x", "") ?? "";
    if (errorCode.contains("6985")) {
      return S.current.ledger_error_tx_rejected_by_user;
    } else if (errorCode.contains("5515")) {
      return S.current.ledger_error_device_locked;
    } else
    if (["6e01", "6a87", "6d02", "6511", "6e00"].any((e) => errorCode.contains(e))) {
      return S.current.ledger_error_wrong_app;
    }
    return null;
  }
}
