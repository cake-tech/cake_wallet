import 'dart:async';

import 'package:ledger_flutter/ledger_flutter.dart';

class CakeBleConnectionManager extends BleConnectionManager {
  /// Ledger Nano X service id
  static const serviceId = '13D63400-2C97-0004-0000-4C6564676572';

  final _bleManager = FlutterReactiveBle();
  final LedgerOptions _options;
  final PermissionRequestCallback? onPermissionRequest;
  final _connectedDevices = <LedgerDevice, GattGateway>{};

  CakeBleConnectionManager({
    required LedgerOptions options,
    this.onPermissionRequest,
  }) : _options = options;

  @override
  Future<void> connect(
      LedgerDevice device, {
        LedgerOptions? options,
      }) async {
    // Check for permissions
    final granted = (await onPermissionRequest?.call(status)) ?? true;
    if (!granted) {
      return;
    }

    // There are numerous issues on the Android BLE stack that leave it hanging
    // when you try to connect to a device that is not in range.
    // To work around this issue use the method connectToAdvertisingDevice to
    // first scan for the device and only if it is found connect to it.
    final c = Completer();

    StreamSubscription? subscription;
    await disconnect(device);

    subscription = _bleManager
        .connectToDevice(
      id: device.id,
      // withServices: [Uuid.parse(serviceId)],
      // prescanDuration: options?.prescanDuration ?? _options.prescanDuration,
      connectionTimeout:
      options?.connectionTimeout ?? _options.connectionTimeout,
    )
        .listen(
          (state) async {
        print("state.connectionState: ${state.connectionState}");
        if (state.connectionState == DeviceConnectionState.connected) {
          final services = await _bleManager.discoverServices(device.id);
          final ledger = DiscoveredLedger(
            device: device,
            subscription: subscription,
            services: services,
          );

          final gateway = LedgerGattGateway(
            bleManager: _bleManager,
            ledger: ledger,
            mtu: options?.mtu ?? _options.mtu,
          );

          await gateway.start();
          _connectedDevices[device] = gateway;

          c.complete();
        }

        if (state.connectionState == DeviceConnectionState.disconnected) {
          await disconnect(device);
        }
      },
      onError: (ex) async {
        await disconnect(device);
        c.completeError(ex);
      },
    );

    return c.future;
  }

  @override
  Future<T> sendOperation<T>(
      LedgerDevice device,
      LedgerOperation<T> operation,
      LedgerTransformer? transformer,
      ) async {
    final d = _connectedDevices[device];
    if (d == null) {
      throw LedgerException(message: 'Unable to send request.');
    }

    return d.sendOperation<T>(
      operation,
      transformer: transformer,
    );
  }

  /// Returns the current status of the BLE subsystem of the host device.
  @override
  BleStatus get status => _bleManager.status;

  /// A stream providing the host device BLE subsystem status updates.
  @override
  Stream<BleStatus> get statusStateChanges => _bleManager.statusStream;

  /// Get a list of connected [LedgerDevice]s.
  @override
  List<LedgerDevice> get devices => _connectedDevices.keys.toList();

  /// A stream providing connection updates for all the connected BLE devices.
  @override
  Stream<ConnectionStateUpdate> get deviceStateChanges =>
      _bleManager.connectedDeviceStream;

  @override
  Future<void> disconnect(LedgerDevice device) async {
    _connectedDevices[device]?.disconnect();
    _connectedDevices.remove(device);
  }

  @override
  Future<void> dispose() async {
    for (var subscription in _connectedDevices.values) {
      await subscription.disconnect();
    }

    _connectedDevices.clear();
  }
}
