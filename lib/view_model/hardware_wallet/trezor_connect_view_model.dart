import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/new-ui/widgets/hardware_wallet/proceed_on_device_sheet.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/hardware/device_connection_type.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/key.dart";
import "package:cw_core/root_dir.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/material.dart";
import "package:mobx/mobx.dart";
import "package:permission_handler/permission_handler.dart";
import "package:trezor_connect/trezor_connect.dart" as connect_sdk;
import "package:trezor_flutter/trezor_flutter.dart" as sdk;

part "trezor_connect_view_model.g.dart";

class TrezorConnectViewModel = TrezorConnectViewModelBase with _$TrezorConnectViewModel;

abstract class TrezorConnectViewModelBase extends HardwareWalletViewModel with Store {
  TrezorConnectViewModelBase(this.trezorConnect, this._secureStorage) {
    if (_doesSupportHardwareWallets) {
      reaction((_) => isBleEnabled, (_) {
        if (isBleEnabled) {
          _initBLE();
        }
      });
      updateBleState();

      if (!Platform.isIOS) {
        trezorUSB = sdk.TrezorInterface.usb();
      }
    }
  }

  final connect_sdk.TrezorConnect trezorConnect;
  final SecureStorage _secureStorage;

  late final sdk.TrezorInterface trezorBLE;
  late final sdk.TrezorInterface trezorUSB;

  sdk.ThpState? _state;

  bool get _doesSupportHardwareWallets {
    if (isMoneroOnly) {
      return DeviceConnectionType.supportedConnectionTypes(
        WalletType.monero,
        HardwareWalletType.trezor,
        Platform.isIOS,
      ).isNotEmpty;
    }

    return true;
  }

  bool _bleIsInitialized = false;

  Future<void> _initBLE() async {
    if (isBleEnabled && !_bleIsInitialized) {
      trezorBLE = sdk.TrezorInterface.ble(
        onPermissionRequest: (_) async {
          if (Platform.isMacOS) {
            return true;
          }

          final Map<Permission, PermissionStatus> statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ].request();

          return statuses.values.where((status) => status.isDenied).isEmpty;
        },
        bleOptions: sdk.BluetoothOptions(maxScanDuration: const Duration(minutes: 5)),
      );
      _bleIsInitialized = true;
    }
  }

  @override
  HardwareWalletType get hardwareWalletType => HardwareWalletType.trezor;

  @override
  @observable
  bool isConnecting = false;

  @override
  @observable
  bool isBleEnabled = false;

  @override
  bool get hasBluetooth => true;

  @override
  Future<void> updateBleState() async {
    final bleState = await sdk.UniversalBle.getBluetoothAvailabilityState();

    final newState = bleState == sdk.AvailabilityState.poweredOn;

    if (newState != isBleEnabled) {
      isBleEnabled = newState;
    }
  }

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() =>
      trezorBLE.scan().map(TrezorHardwareWalletDevice.new);

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() =>
      trezorUSB.devices.then((devices) => devices.map(TrezorHardwareWalletDevice.new).toList());

  @override
  Future<void> stopScanning() async {
    if (_bleIsInitialized) {
      await trezorBLE.stopScanning();
    }
    if (!Platform.isIOS) {
      await trezorUSB.stopScanning();
    }
  }

  sdk.TrezorClient? _client;

  Completer<String?>? _pinCompleter;

  @observable
  TrezorParingState paringState = TrezorParingState.initial;

  void setParingPin(String pin) => _pinCompleter?.complete(pin);

  @override
  @action
  Future<bool> connectDevice(
    HardwareWalletDevice device,
    WalletType type, [
    bool isRetry = false,
  ]) async {
    if (device is! TrezorHardwareWalletDevice) {
      return false;
    }
    if (isConnecting) {
      return false;
    }
    isConnecting = true;
    paringState = TrezorParingState.initial;

    try {
      final trezorInterface =
          device.connectionType == HardwareWalletConnectionType.ble ? trezorBLE : trezorUSB;
      final connection = await trezorInterface.connect(device.device);

      if (!isRetry) {
        unawaited(
          showModalBottomSheet(
            context: navigatorKey.currentContext!,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            useSafeArea: true,
            builder: (_) => HardwareWalletProceedOnDeviceSheet(
              hardwareWalletType: hardwareWalletType,
              trezorConnectVM: this,
              onRetry: () => connectDevice(device, type, true),
            ),
          ),
        );
      }

      Future<String> onPinCode() async {
        _pinCompleter = Completer<String?>();
        paringState = TrezorParingState.enterPin;

        final res = await _pinCompleter!.future;
        paringState = TrezorParingState.verifyingPin;
        if (res == null) {
          throw Exception();
        }
        return res;
      }

      final deviceInfo = await _deviceName;

      _state ??= await _getState();
      _client = sdk.TrezorClient.getClientForConnection(
        connection,
        _state!,
        "Cake Wallet",
        deviceInfo,
        onPinCode,
      );

      await _client!.createChannel();

      if (!_state!.pairingCredentials.any((c) => c.autoconnect == true)) {
        if (_client case final sdk.TrezorClientV2 clientV2) {
          try {
            final auto = await clientV2.getAutoPairingCredentials();
            _state!.setPairingCredentials([auto]);
            await _saveState();
          } catch (_) {}
        }
      }

      paringState = TrezorParingState.success;
      return true;
    } catch (e) {
      await _client?.connection.disconnect();
      _client = null;
      _state = sdk.ThpState();
      // rethrow;
      paringState = TrezorParingState.fail(e.toString());
      printV(e);
      return false;
    } finally {
      isConnecting = false;
    }
  }

  Future<String> get _deviceName async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return (await deviceInfo.androidInfo).model;
    }
    if (Platform.isIOS) {
      return (await deviceInfo.iosInfo).name;
    }
    return "Computer";
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
        throw Exception("Unexpected wallet type: ${wallet.type} for trezor");
    }
  }

  final EncryptionFileUtils _encryptionFileUtils = encryptionFileUtilsFor(true);
  static const String _secureStorageKey = "com.cakewallet.trezor/thp_state";

  Future<String> get _thpJsonFile async => "${(await getAppDir()).path}/thp_state.json.enc";

  Future<sdk.ThpState> _getState() async {
    final password = await _secureStorage.read(key: _secureStorageKey);
    if (password == null) {
      return _saveState();
    }
    try {
      final state = await _encryptionFileUtils.read(path: await _thpJsonFile, password: password);
      return sdk.ThpState.fromJson(state);
    } catch (_) {
      return _saveState();
    }
  }

  Future<sdk.ThpState> _saveState() async {
    try {
      final password = generateKey();
      await _secureStorage.write(key: _secureStorageKey, value: password);

      final file = File(await _thpJsonFile);
      if (!file.existsSync()) {
        file.createSync();
      }

      final state = _state ?? sdk.ThpState();
      await _encryptionFileUtils.write(
        path: file.path,
        password: password,
        data: jsonEncode(state.toMap()),
      );
      _state = state;
      return state;
    } catch (_) {
      throw Exception("Unable to save Trezor State");
    }
  }

  Future<bool> syncKeyImages(WalletBase wallet) async {
    if (wallet.type == WalletType.monero) {
      try {
        await monero!.syncTrezor(wallet);
      } catch (_) {
        return false;
      }
    }
    return true;
  }
}

abstract class TrezorParingState {
  static TrezorParingState initial = InitialTrezorParingState();
  static TrezorParingState enterPin = EnterPinTrezorParingState();
  static TrezorParingState verifyingPin = VerifyingPinTrezorParingState();
  static TrezorParingState success = SuccessTrezorParingState();

  static TrezorParingState fail(String message) => FailTrezorParingState(message);
}

class InitialTrezorParingState extends TrezorParingState {}

class EnterPinTrezorParingState extends TrezorParingState {}

class VerifyingPinTrezorParingState extends TrezorParingState {}

class SuccessTrezorParingState extends TrezorParingState {}

class FailTrezorParingState extends TrezorParingState {
  FailTrezorParingState(this.message);

  final String message;
}
