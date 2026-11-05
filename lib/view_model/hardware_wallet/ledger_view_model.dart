import "dart:async";
import "dart:io";

import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cake_wallet/view_model/hardware_wallet/ledger_view_model_dependencies.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart" as sdk;
import "package:mobx/mobx.dart";
import "package:permission_handler/permission_handler.dart";

part "ledger_view_model.g.dart";

class LedgerViewModel = LedgerViewModelBase with _$LedgerViewModel;

abstract class LedgerViewModelBase extends HardwareWalletViewModel with Store {
  LedgerViewModelBase(this._dependencies) {
    if (_dependencies.supportsHardwareWallets) {
      reaction((_) => isBleEnabled, (_) {
        if (isBleEnabled) {
          _initBLE();
        }
      });

      reaction((_) => _dependencies.currentWallet(), (wallet) async {
        if (_attachedTronWallet != null && !identical(wallet, _attachedTronWallet)) {
          _clearAttachedTronWallet();
        }
        if (wallet != null && wallet.type != _connectingWalletType) {
          await close();
        }
      });

      if (!Platform.isIOS) {
        ledgerPlusUSB = sdk.LedgerInterface.usb();
      }
    }
  }

  late final sdk.LedgerInterface ledgerPlusBLE;
  late final sdk.LedgerInterface ledgerPlusUSB;

  final LedgerViewModelDependencies _dependencies;

  @override
  HardwareWalletType get hardwareWalletType => HardwareWalletType.ledger;

  @override
  @observable
  bool isBleEnabled = false;

  @override
  @observable
  bool isConnecting = false;

  @override
  bool get hasBluetooth => true;

  bool _bleIsInitialized = false;

  Future<void> _initBLE() async {
    if (isBleEnabled && !_bleIsInitialized) {
      ledgerPlusBLE = sdk.LedgerInterface.ble(
        onPermissionRequest: (_) async {
          if (Platform.isMacOS) {
            return true;
          }

          final statuses = await [
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
  Future<void> updateBleState() async {
    final bleState = await sdk.UniversalBle.getBluetoothAvailabilityState();

    final newState = bleState == sdk.AvailabilityState.poweredOn;

    if (newState != isBleEnabled) {
      isBleEnabled = newState;
    }
  }

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() =>
      ledgerPlusBLE.scan().map(LedgerHardwareWalletDevice.new);

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() =>
      ledgerPlusUSB.devices.then((devices) => devices.map(LedgerHardwareWalletDevice.new).toList());

  @override
  Future<List<HardwareWalletDevice>> getConnectedBleDevices() async {
    if (!_bleIsInitialized) {
      return const [];
    }
    return (await ledgerPlusBLE.devices).map(LedgerHardwareWalletDevice.new).toList();
  }

  @override
  Future<void> stopScanning() async {
    if (_bleIsInitialized) {
      await ledgerPlusBLE.stopScanning();
    }
    if (!Platform.isIOS) {
      await ledgerPlusUSB.stopScanning();
    }
  }

  @override
  @action
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    if (device is! LedgerHardwareWalletDevice) {
      return false;
    }

    if (isConnecting) {
      return false;
    }

    final attempt = ++_connectionAttempt;
    final previousAttempt = _connectionSettlement;
    final settlement = Completer<void>();
    _connectionSettlement = settlement.future;
    isConnecting = true;
    _connectingWalletType = type;
    _disconnectedDuringConnect = false;
    StreamSubscription<sdk.BleConnectionState>? subscription;
    try {
      await previousAttempt;
      if (attempt != _connectionAttempt) return false;
      final previousSubscription = _connectionChangeSubscription;
      _connectionChangeSubscription = null;
      try {
        await previousSubscription?.cancel();
      } catch (_) {}
      try {
        await _disconnecting;
      } catch (_) {}
      if (attempt != _connectionAttempt) return false;
      _clearAttachedTronWallet();
      final oldConnection = _connection;
      _connection = null;
      if (oldConnection != null) {
        try {
          final disconnecting = oldConnection.disconnect().catchError((_) {});
          _disconnecting = disconnecting;
          await disconnecting;
        } catch (_) {}
      }
      if (attempt != _connectionAttempt) return false;

      final states = _dependencies.deviceStateChanges?.call(device) ??
          (device.connectionType == HardwareWalletConnectionType.ble ? ledgerPlusBLE : ledgerPlusUSB)
              .deviceStateChanges(device.device.id);
      subscription = states.listen((event) {
        if (attempt == _connectionAttempt) _connectionChangeListener(event);
      });
      _connectionChangeSubscription = subscription;
      final connect = _dependencies.connectDevice;
      final connection = connect != null
          ? await connect(device)
          : await (device.connectionType == HardwareWalletConnectionType.ble
                  ? ledgerPlusBLE
                  : ledgerPlusUSB)
              .connect(device.device);
      if (attempt != _connectionAttempt || _disconnectedDuringConnect) {
        await connection.disconnect().catchError((_) {});
        await subscription.cancel();
        if (identical(_connectionChangeSubscription, subscription)) {
          _connectionChangeSubscription = null;
        }
        return false;
      }
      _connection = connection;
      return true;
    } catch (e) {
      printV(e);
      try {
        await subscription?.cancel();
      } catch (_) {}
      if (identical(_connectionChangeSubscription, subscription)) {
        _connectionChangeSubscription = null;
      }
      return false;
    } finally {
      settlement.complete();
      if (identical(_connectionSettlement, settlement.future)) {
        _connectionSettlement = null;
      }
      if (attempt == _connectionAttempt) isConnecting = false;
    }
  }

  StreamSubscription<sdk.BleConnectionState>? _connectionChangeSubscription;
  sdk.LedgerConnection? _connection;
  WalletType? _connectingWalletType;
  WalletBase? _attachedTronWallet;
  bool _disconnectedDuringConnect = false;
  int _connectionAttempt = 0;
  Future<void>? _connectionSettlement;
  Future<void>? _disconnecting;
  bool suppressMoneroReconnectPrompt = false;

  void _clearAttachedTronWallet() {
    final wallet = _attachedTronWallet;
    _attachedTronWallet = null;
    if (wallet != null) _dependencies.clearTronService(wallet);
  }

  void _connectionChangeListener(sdk.BleConnectionState event) {
    printV("Ledger Device State Changed: $event");
    if (event == sdk.BleConnectionState.disconnected) {
      if (isConnecting) {
        _disconnectedDuringConnect = true;
      }
      final connection = _connection;
      _connection = null;
      if (connection != null) {
        _disconnecting = connection.disconnect().catchError((_) {});
      }
      _clearAttachedTronWallet();
      if (isConnecting) return;
      if (_connectingWalletType == WalletType.monero) {
        _dependencies.onMoneroDisconnected(suppressMoneroReconnectPrompt);
      }
    }
  }

  @override
  bool isConnected(WalletType type) => _connection != null && !_connection!.isDisconnected;

  sdk.LedgerConnection get connection => _connection!;

  @override
  Future<void> initWallet(WalletBase wallet) async {
    if (wallet.type != WalletType.tron) {
      return _dependencies.initWallet(wallet, connection);
    }
    if (!identical(_attachedTronWallet, wallet)) _clearAttachedTronWallet();
    final attachedConnection = connection;
    _attachedTronWallet = wallet;
    try {
      await _dependencies.initWallet(wallet, attachedConnection);
      if (!identical(_attachedTronWallet, wallet) ||
          !identical(_connection, attachedConnection) ||
          attachedConnection.isDisconnected) {
        throw StateError("Ledger disconnected while initializing the wallet");
      }
    } catch (_) {
      if (identical(_attachedTronWallet, wallet)) {
        _clearAttachedTronWallet();
      } else {
        _dependencies.clearTronService(wallet);
      }
      rethrow;
    }
  }

  @override
  HardwareWalletService getHardwareWalletService(WalletType type) =>
      _dependencies.getHardwareWalletService(type, connection);

  @override
  String? interpretErrorCode(String error) {
    if (error.contains("Make sure no other program is communicating with the Ledger")) {
      return error;
    }

    final errorRegex = RegExp(r"(?:0x\S*?|[0-9a-f]{4})(?= )").firstMatch(error.toString());

    final errorCode = errorRegex?.group(0).toString().replaceAll("0x", "") ?? "";
    if (errorCode.contains("6985")) {
      return S.current.ledger_error_tx_rejected_by_user;
    } else if (errorCode.contains("5515")) {
      return S.current.ledger_error_device_locked;
    } else if (["6e01", "6a87", "6d02", "6511", "6e00"].any(errorCode.contains)) {
      return S.current.ledger_error_wrong_app;
    }
    return null;
  }

  @override
  Future<void> close() async {
    ++_connectionAttempt;
    final subscription = _connectionChangeSubscription;
    final connection = _connection;
    final previousDisconnect = _disconnecting;
    Future<void> disconnectConnections() async {
      try {
        await connection?.disconnect();
      } catch (_) {}
      try {
        await previousDisconnect;
      } catch (_) {}
    }

    final disconnecting = disconnectConnections();
    _connectingWalletType = null;
    _connectionChangeSubscription = null;
    _connection = null;
    _disconnecting = disconnecting;
    isConnecting = false;
    _clearAttachedTronWallet();
    try {
      printV("Resetting ledger VM");
      await subscription?.cancel();
    } catch (_) {}
    await disconnecting;
    if (identical(_disconnecting, disconnecting)) _disconnecting = null;
    try {
      await stopScanning();
    } catch (_) {}
  }
}
