import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
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

const trezorUseNative = [WalletType.bitcoin, WalletType.monero];

class TrezorConnectViewModel = TrezorConnectViewModelBase with _$TrezorConnectViewModel;

abstract class TrezorConnectViewModelBase extends HardwareWalletViewModel with Store {
  TrezorConnectViewModelBase(this.trezorConnect, this._secureStorage) {
    if (_doesSupportHardwareWallets) {
      reaction((_) => isBleEnabled, (_) {
        if (isBleEnabled) {
          _initBLE();
        }
      });

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
  Completer<TrezorDeviceSettings>? _settingsCompleter;
  Completer<bool>? _retryCompleter;
  bool _isPairingCancelled = false;

  /// Settings to apply on the next [connectDevice] instead of asking the user.
  /// Set by [prepareReconnect] and consumed by [connectDevice].
  TrezorDeviceSettings? _presetSettings;

  /// Settings the live session was created with, persisted per wallet once the
  /// wallet is known (see [initWallet] and [rememberWalletSettings]).
  TrezorDeviceSettings? _sessionSettings;

  @observable
  TrezorParingState paringState = TrezorParingState.initial;

  void setParingPin(String pin) => _complete(_pinCompleter, pin);

  void setDeviceSettings(TrezorDeviceSettings settings) => _complete(_settingsCompleter, settings);

  /// Called by the pairing sheet when the user taps "Try again" after a failed
  /// attempt. The pending [connectDevice] call runs another attempt and reports
  /// the final outcome to its caller, so the caller never loses track of a
  /// connection that only succeeded on a retry.
  void retryPairing() => _complete(_retryCompleter, true);

  /// Called by the pairing sheet when the user exits it. Unblocks whatever the
  /// pending [connectDevice] call is waiting on (pairing code, settings, retry
  /// or an on-device prompt) so it can clean up and return false instead of
  /// hanging with [isConnecting] stuck at true.
  Future<void> cancelPairing() async {
    _isPairingCancelled = true;
    _complete(_pinCompleter, null);
    _complete(_retryCompleter, false);
    if (!(_settingsCompleter?.isCompleted ?? true)) {
      _settingsCompleter!.completeError(const _PairingCancelledException());
    }
    try {
      await _client?.cancel();
    } catch (e) {
      printV(e);
    }
  }

  static void _complete<T>(Completer<T>? completer, T value) {
    if (completer != null && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  @override
  @action
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    if (device is! TrezorHardwareWalletDevice) {
      return false;
    }
    if (isConnecting) {
      return false;
    }
    isConnecting = true;
    _isPairingCancelled = false;
    paringState = TrezorParingState.initial;

    // A reconnect for a wallet we already know reuses the settings it was set
    // up with, so the user is not asked for the passphrase in the app again.
    // Consumed up front so a failed attempt can never leak them into a later,
    // unrelated connect (e.g. restoring a different wallet).
    final preset = _presetSettings;
    _presetSettings = null;

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
        ),
      ),
    );

    try {
      while (true) {
        try {
          await _connect(device, preset);
          paringState = TrezorParingState.success;
          return true;
        } catch (e) {
          await _resetClient();
          if (_isPairingCancelled || e is _PairingCancelledException) {
            return false;
          }
          printV(e);
          paringState = TrezorParingState.fail(e.toString());

          // Keep the sheet (and this call) alive until the user decides to
          // retry or to give up, so a retry's success reaches our caller.
          _retryCompleter = Completer<bool>();
          if (!await _retryCompleter!.future) {
            return false;
          }
          paringState = TrezorParingState.initial;
        }
      }
    } finally {
      isConnecting = false;
      _retryCompleter = null;
      _pinCompleter = null;
      _settingsCompleter = null;
    }
  }

  /// One connection attempt. Throws on any failure; the caller decides whether
  /// to retry.
  Future<void> _connect(TrezorHardwareWalletDevice device, TrezorDeviceSettings? preset) async {
    final trezorInterface =
        device.connectionType == HardwareWalletConnectionType.ble ? trezorBLE : trezorUSB;
    final connection = await trezorInterface.connect(device.device);

    Future<String> onPinCode() async {
      _pinCompleter = Completer<String?>();
      paringState = TrezorParingState.enterPin;

      final res = await _pinCompleter!.future;
      if (res == null) {
        throw const _PairingCancelledException();
      }
      paringState = TrezorParingState.verifyingPin;
      return res;
    }

    // Every attempt starts from a fresh THP channel built on the persisted
    // pairing credentials. Reusing the in-memory state of an earlier session
    // would skip the handshake and talk on a channel the device may have
    // dropped in the meantime, which the device rejects with
    // ThpUnallocatedChannel.
    final state = await _loadState();
    _state = state;
    _client = sdk.TrezorClient.getClientForConnection(
      connection,
      state,
      "Cake Wallet",
      await _deviceName,
      onPinCode,
    );

    final client = _client!;
    await client.createChannel();

    final hasAutoPairingCredentials = state.pairingCredentials.any((c) => c.autoconnect == true);
    final isAutoPairingAvailable = client is sdk.TrezorClientV2 && !hasAutoPairingCredentials;

    // With "passphrase always on device" enabled the device already asked for
    // the passphrase while the channel (and its initial session) was created,
    // so the session is bound to what the user entered there. Asking in the
    // app or creating a second session would only prompt them a second time.
    final passphraseAlwaysOnDevice = client.passphraseAlwaysOnDevice;

    final TrezorDeviceSettings settings;
    if (preset != null) {
      settings = preset;
    } else if (!isAutoPairingAvailable && passphraseAlwaysOnDevice) {
      // Nothing left for the user to decide.
      settings = const TrezorDeviceSettings(enableAutoParing: false, passphraseOnDevice: true);
    } else {
      paringState = TrezorParingState.awaitingSettings(
        isAutoPairingAvailable: isAutoPairingAvailable,
        passphraseAlwaysOnDevice: passphraseAlwaysOnDevice,
      );
      _settingsCompleter = Completer<TrezorDeviceSettings>();
      settings = await _settingsCompleter!.future;
    }

    if (settings.enableAutoParing && isAutoPairingAvailable) {
      if (client case final sdk.TrezorClientV2 clientV2) {
        try {
          final auto = await clientV2.getAutoPairingCredentials();
          state.setPairingCredentials([auto]);
          await _saveState();
        } catch (e) {
          printV(e);
        }
      }
    }

    final usesPassphrase = settings.passphraseOnDevice || (settings.passphrase ?? "").isNotEmpty;
    if (usesPassphrase && !passphraseAlwaysOnDevice) {
      paringState = TrezorParingState.awaitingPassphrase;
      final passphrase = settings.passphraseOnDevice
          ? const sdk.TrezorPassphrase.onDevice()
          : sdk.TrezorPassphrase.value(settings.passphrase ?? "");
      await client.createSession(passphrase);
    } else {
      paringState = TrezorParingState.initial;
    }

    _sessionSettings = passphraseAlwaysOnDevice
        ? TrezorDeviceSettings(
            enableAutoParing: settings.enableAutoParing,
            passphraseOnDevice: true,
          )
        : settings;
  }

  Future<void> _resetClient() async {
    try {
      await _client?.connection.disconnect();
    } catch (e) {
      printV(e);
    }
    _client = null;
    _sessionSettings = null;
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
  bool isConnected(WalletType type) => trezorUseNative.contains(type)
      ? _client != null && _client?.connection.isDisconnected == false
      : true;

  @override
  Future<List<HardwareWalletDevice>> getConnectedDevices() async {
    final devices = <HardwareWalletDevice>[];
    try {
      // A Trezor with a live BLE link stops advertising, so a scan never lists
      // it; the SDK's connection manager still knows about it.
      if (_bleIsInitialized) {
        devices.addAll((await trezorBLE.devices).map(TrezorHardwareWalletDevice.new));
      }
    } catch (e) {
      printV(e);
    }
    return devices;
  }

  /// Trezor errors carry their own description, so surface it instead of
  /// letting callers fall back to a generic (Ledger) connection error and
  /// silently bail out of the flow.
  @override
  String? interpretErrorCode(String error) {
    if (error.contains("ThpDeviceLocked")) {
      return S.current.trezor_error_device_locked;
    }
    if (error.contains("ThpUnallocatedChannel") || error.contains("ThpDecryptionFailed")) {
      return S.current.trezor_error_channel_lost;
    }
    if (error.contains("DeviceNotConnectedException") || error.contains("isDisconnected")) {
      return S.current.trezor_error_disconnected;
    }
    return error;
  }

  @override
  HardwareWalletService getHardwareWalletService(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return monero!.getTrezorHardwareWalletService(_client!);
      case WalletType.bitcoin:
        return bitcoin!.getTrezorHardwareWalletService(null, _client!, true);
      case WalletType.litecoin:
        return bitcoin!.getTrezorHardwareWalletService(trezorConnect, null, false);
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.getTrezorHardwareWalletService(trezorConnect);
      default:
        throw UnimplementedError();
    }
  }

  @override
  Future<void> prepareReconnect(WalletBase wallet) async {
    if (!_usesPersistedSettings(wallet)) return;

    _presetSettings = await _loadWalletSettings(wallet);
  }

  @override
  Future<void> rememberWalletSettings(WalletBase wallet) async {
    final settings = _sessionSettings;
    if (settings == null || !_usesPersistedSettings(wallet)) return;

    await _saveWalletSettings(wallet, settings);
  }

  bool _usesPersistedSettings(WalletBase wallet) =>
      trezorUseNative.contains(wallet.type) &&
      wallet.hardwareWalletType == HardwareWalletType.trezor;

  static const String _passphraseModeKeyPrefix = "com.cakewallet.trezor/passphrase_mode/";
  static const String _passphraseKeyPrefix = "com.cakewallet.trezor/passphrase/";
  static const String _passphraseModeDevice = "device";
  static const String _passphraseModeApp = "app";
  static const String _passphraseModeNone = "none";

  String _walletKey(WalletBase wallet) => "${walletTypeToString(wallet.type)}_${wallet.name}";

  Future<TrezorDeviceSettings?> _loadWalletSettings(WalletBase wallet) async {
    try {
      final key = _walletKey(wallet);
      final mode = await _secureStorage.read(key: _passphraseModeKeyPrefix + key);

      switch (mode) {
        case _passphraseModeDevice:
          return const TrezorDeviceSettings(enableAutoParing: true, passphraseOnDevice: true);
        case _passphraseModeApp:
          final passphrase = await _secureStorage.read(key: _passphraseKeyPrefix + key);
          // Without the stored secret the session cannot be rebuilt silently,
          // so fall back to asking.
          if (passphrase == null || passphrase.isEmpty) return null;

          return TrezorDeviceSettings(
            enableAutoParing: true,
            passphraseOnDevice: false,
            passphrase: passphrase,
          );
        case _passphraseModeNone:
          return const TrezorDeviceSettings(enableAutoParing: true, passphraseOnDevice: false);
        default:
          return null;
      }
    } catch (e) {
      printV(e);
      return null;
    }
  }

  Future<void> _saveWalletSettings(WalletBase wallet, TrezorDeviceSettings settings) async {
    try {
      final key = _walletKey(wallet);
      final passphrase = settings.passphrase ?? "";
      final mode = settings.passphraseOnDevice
          ? _passphraseModeDevice
          : passphrase.isNotEmpty
              ? _passphraseModeApp
              : _passphraseModeNone;

      await _secureStorage.write(key: _passphraseModeKeyPrefix + key, value: mode);
      if (mode == _passphraseModeApp) {
        await _secureStorage.write(key: _passphraseKeyPrefix + key, value: passphrase);
      } else {
        await _secureStorage.delete(key: _passphraseKeyPrefix + key);
      }
    } catch (e) {
      printV(e);
    }
  }

  @override
  Future<void> initWallet(WalletBase wallet) async {
    await rememberWalletSettings(wallet);

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

  /// Builds a fresh [sdk.ThpState] (no channel, handshake phase) carrying the
  /// persisted pairing credentials, or an empty one when nothing is persisted.
  Future<sdk.ThpState> _loadState() async {
    try {
      final password = await _secureStorage.read(key: _secureStorageKey);
      if (password == null) {
        return sdk.ThpState();
      }
      final state = await _encryptionFileUtils.read(path: await _thpJsonFile, password: password);
      return sdk.ThpState.fromJson(state);
    } catch (e) {
      printV(e);
      return sdk.ThpState();
    }
  }

  Future<void> _saveState() async {
    try {
      final password =
          await _secureStorage.read(key: _secureStorageKey) ?? await _createStatePassword();

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
    } catch (_) {
      throw Exception("Unable to save Trezor State");
    }
  }

  Future<String> _createStatePassword() async {
    final password = generateKey();
    await _secureStorage.write(key: _secureStorageKey, value: password);
    return password;
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
  static TrezorParingState success = SuccessTrezorParingState();
  static TrezorParingState verifyingPin = VerifyingPinTrezorParingState();
  static TrezorParingState awaitingPassphrase = AwaitingPassphraseTrezorParingState();

  static TrezorParingState awaitingSettings({
    required bool isAutoPairingAvailable,
    required bool passphraseAlwaysOnDevice,
  }) =>
      AwaitingSettingsTrezorParingState(
        isAutoPairingAvailable: isAutoPairingAvailable,
        passphraseAlwaysOnDevice: passphraseAlwaysOnDevice,
      );

  static TrezorParingState fail(String message) => FailTrezorParingState(message);
}

class InitialTrezorParingState extends TrezorParingState {}

class EnterPinTrezorParingState extends TrezorParingState {}

class VerifyingPinTrezorParingState extends TrezorParingState {}

class AwaitingSettingsTrezorParingState extends TrezorParingState {
  AwaitingSettingsTrezorParingState({
    required this.isAutoPairingAvailable,
    required this.passphraseAlwaysOnDevice,
  });

  final bool isAutoPairingAvailable;

  /// The device is configured to always ask for the passphrase on its own
  /// screen, so there is nothing to configure about it in the app.
  final bool passphraseAlwaysOnDevice;
}

/// Thrown inside a connection attempt when the user exits the pairing sheet.
class _PairingCancelledException implements Exception {
  const _PairingCancelledException();
}

class AwaitingPassphraseTrezorParingState extends TrezorParingState {}

class SuccessTrezorParingState extends TrezorParingState {}

class FailTrezorParingState extends TrezorParingState {
  FailTrezorParingState(this.message);

  final String message;
}

class TrezorDeviceSettings {
  const TrezorDeviceSettings({
    required this.enableAutoParing,
    required this.passphraseOnDevice,
    this.passphrase,
  });

  final bool enableAutoParing;
  final bool passphraseOnDevice;
  final String? passphrase;
}
