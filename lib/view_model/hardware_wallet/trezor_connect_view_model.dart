import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/new-ui/widgets/hardware_wallet/trezor_paring_sheet.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trezor_connect/trezor_connect.dart' as connect_sdk;
import 'package:trezor_flutter/trezor_flutter.dart' as sdk;

part 'trezor_connect_view_model.g.dart';

class TrezorConnectViewModel = TrezorConnectViewModelBase with _$TrezorConnectViewModel;

abstract class TrezorConnectViewModelBase extends HardwareWalletViewModel with Store {
  final connect_sdk.TrezorConnect trezorConnect;

  late final sdk.TrezorInterface trezorBLE;
  late final sdk.TrezorInterface trezorUSB;

  sdk.ThpState _state = sdk.ThpState();

  TrezorConnectViewModelBase(this.trezorConnect) {
    if (_doesSupportHardwareWallets) {
      reaction((_) => isBleEnabled, (_) {
        if (isBleEnabled) _initBLE();
      });
      updateBleState();

      if (!Platform.isIOS) {
        trezorUSB = sdk.TrezorInterface.usb();
      }
    }
  }

  bool get _doesSupportHardwareWallets {
    if (isMoneroOnly) {
      return DeviceConnectionType.supportedConnectionTypes(
              WalletType.monero, HardwareWalletType.trezor, Platform.isIOS)
          .isNotEmpty;
    }

    return true;
  }

  bool _bleIsInitialized = false;

  Future<void> _initBLE() async {
    if (isBleEnabled && !_bleIsInitialized) {
      trezorBLE = sdk.TrezorInterface.ble(
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
  HardwareWalletType get hardwareWalletType => HardwareWalletType.trezor;

  @override
  @observable
  bool isBleEnabled = false;

  @override
  bool get hasBluetooth => true;

  @override
  Future<void> updateBleState() async {
    final bleState = await sdk.UniversalBle.getBluetoothAvailabilityState();

    final newState = bleState == sdk.AvailabilityState.poweredOn;

    if (newState != isBleEnabled) isBleEnabled = newState;
  }

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() =>
      trezorBLE.scan().map((d) => TrezorHardwareWalletDevice(d));

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() => trezorUSB.devices
      .then((devices) => devices.map((d) => TrezorHardwareWalletDevice(d)).toList());

  @override
  Future<void> stopScanning() async {
    if (_bleIsInitialized) await trezorBLE.stopScanning();
    if (!Platform.isIOS) await trezorUSB.stopScanning();
  }

  bool _isConnecting = false;
  sdk.TrezorClient? _client;

  @override
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    if (!(device is TrezorHardwareWalletDevice)) return false;
    if (_isConnecting) return false;
    _isConnecting = true;

    try {
      final trezorInterface =
          device.connectionType == HardwareWalletConnectionType.ble ? trezorBLE : trezorUSB;
      final connection = await trezorInterface.connect(device.device);

      Future<String> onPinCode() async {
        final res = await showModalBottomSheet<String?>(
          isScrollControlled: true,
          context: navigatorKey.currentContext!,
          backgroundColor: Colors.transparent,
          builder: (context) => HardwareWalletTrezorParingSheet(),
        );

        if (res == null) throw Exception();
        return res;
      }

      _client = sdk.TrezorClient.getClientForConnection(
        connection,
        _state,
        "Cake Wallet",
        "Phone",
        onPinCode,
      );

      await _client!.createChannel();

      return true;
    } catch (e) {
      await _client?.connection.disconnect();
      _isConnecting = false;
      _client = null;
      _state = sdk.ThpState();
      // rethrow;
      printV(e);
      return false;
    }
  }

  @override
  bool isConnected(WalletType type) => type == WalletType.monero
      ? _client != null && _client?.connection.isDisconnected == false
      : true;

  @override
  HardwareWalletService getHardwareWalletService(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return monero!.getTrezorHardwareWalletService(_client!);
      case WalletType.bitcoin:
        return bitcoin!.getTrezorHardwareWalletService(trezorConnect, true);
      case WalletType.litecoin:
        return bitcoin!.getTrezorHardwareWalletService(trezorConnect, false);
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.getTrezorHardwareWalletService(trezorConnect);
      default:
        throw UnimplementedError();
    }
  }

  @override
  Future<void> initWallet(WalletBase wallet) async {
    switch (wallet.type) {
      case WalletType.monero:
        return monero!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.bitcoin:
      case WalletType.litecoin:
        return bitcoin!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      default:
        throw Exception('Unexpected wallet type: ${wallet.type} for trezor');
    }
  }
}
