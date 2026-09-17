import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/hardware_wallet/trezor_wallet_settings_storage.dart";
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

export "package:cake_wallet/core/hardware_wallet/trezor_wallet_settings_storage.dart"
    show TrezorDeviceSettings;

part "trezor_connect_view_model.g.dart";

const trezorUseNative = [WalletType.bitcoin, WalletType.monero];

class TrezorConnectViewModel = TrezorConnectViewModelBase with _$TrezorConnectViewModel;

abstract class TrezorConnectViewModelBase extends HardwareWalletViewModel with Store {
  TrezorConnectViewModelBase(this.trezorConnect, this._secureStorage, this._walletSettings) {
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
  final TrezorWalletSettingsStorage _walletSettings;

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
  Completer<String>? _passphraseCompleter;
  Completer<bool>? _retryCompleter;

  /// Completes when the user exits the pairing sheet. Independent of the
  /// stage-specific completers so a cancel can interrupt any awaited stage,
  /// including the BLE connect that runs before any of them exist.
  Completer<void>? _cancelCompleter;

  bool get _isPairingCancelled => _cancelCompleter?.isCompleted ?? false;

  /// Settings to apply on the next [connectDevice] instead of asking the user.
  /// Set by [prepareReconnect] and consumed by [connectDevice].
  TrezorDeviceSettings? _presetSettings;

  /// Wallet (see [_walletKey]) the preset in [_presetSettings] was loaded for.
  String? _presetWalletKey;

  /// Settings the live session was created with, persisted per wallet once the
  /// wallet is known (see [initWallet] and [rememberWalletSettings]).
  TrezorDeviceSettings? _sessionSettings;

  /// Wallet the live session is bound to, or null while the session is not yet
  /// attributed (fresh restore). A session must never be used, nor its
  /// settings persisted, for a different wallet: with one device and several
  /// Cake wallets it may be bound to another wallet's passphrase.
  String? _sessionWalletKey;

  @observable
  TrezorParingState paringState = TrezorParingState.initial;

  void setParingPin(String pin) => _complete(_pinCompleter, pin);

  void setDeviceSettings(TrezorDeviceSettings settings) => _complete(_settingsCompleter, settings);

  /// Called by the pairing sheet with the passphrase typed for an app-side
  /// passphrase wallet. Used for this session only, never stored.
  void setPassphrase(String passphrase) => _complete(_passphraseCompleter, passphrase);

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
    _complete(_cancelCompleter, null);
    _complete(_pinCompleter, null);
    _complete(_retryCompleter, false);
    if (!(_settingsCompleter?.isCompleted ?? true)) {
      _settingsCompleter!.completeError(const _PairingCancelledException());
    }
    if (!(_passphraseCompleter?.isCompleted ?? true)) {
      _passphraseCompleter!.completeError(const _PairingCancelledException());
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

  /// Cleanup left behind by an attempt that was cancelled while its transport
  /// connect was still in flight. The SDK disconnects by device id through a
  /// shared connection manager, so that late disconnect must finish before a
  /// new attempt brings up its own link, or it would tear the new one down.
  Future<void>? _pendingCleanup;

  /// Awaits [future] unless the pairing is cancelled first, in which case a
  /// [_PairingCancelledException] is thrown and the late result is handed to
  /// [onLateResult]; that cleanup is awaited by the next attempt.
  Future<T> _untilCancelled<T>(Future<T> future, {Future<void> Function(T)? onLateResult}) {
    final cancel = _cancelCompleter!.future.then<T>((_) {
      if (onLateResult != null) {
        final previous = _pendingCleanup ?? Future<void>.value();
        _pendingCleanup =
            previous.then((_) => future.then(onLateResult)).catchError((Object e) => printV(e));
      }
      throw const _PairingCancelledException();
    });
    return Future.any<T>([future, cancel]);
  }

  Future<void> _awaitPendingCleanup() async {
    final pending = _pendingCleanup;
    if (pending == null) return;
    await _untilCancelled(pending);
    if (identical(_pendingCleanup, pending)) {
      _pendingCleanup = null;
    }
  }

  void _throwIfCancelled() {
    if (_isPairingCancelled) {
      throw const _PairingCancelledException();
    }
  }

  @override
  @action
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    // A reconnect for a wallet we already know reuses the settings it was set
    // up with, so the user is not asked for the passphrase in the app again.
    // Consumed before any early return so neither a failed nor a rejected
    // attempt can leak them into a later, unrelated connect (e.g. restoring a
    // different wallet).
    final preset = _presetSettings;
    final presetWalletKey = _presetWalletKey;
    _presetSettings = null;
    _presetWalletKey = null;

    if (device is! TrezorHardwareWalletDevice) {
      return false;
    }
    if (isConnecting) {
      return false;
    }
    isConnecting = true;
    _cancelCompleter = Completer<void>();
    paringState = TrezorParingState.initial;

    return _runWithPairingSheet(
      attempt: () async {
        await _connect(device, preset);
        // Known wallet (reconnect) or not yet attributed (restore).
        _sessionWalletKey = presetWalletKey;
      },
      onFailure: _resetClient,
    );
  }

  /// Re-runs the session setup on an already connected device so a new wallet
  /// can be restored with its own passphrase choice. Skips the device scan but
  /// still asks (or lets the device ask) for the passphrase, then binds a fresh
  /// session; a "no passphrase" choice explicitly rebinds the empty passphrase
  /// so a previous passphrase wallet is not silently reused.
  @override
  @action
  Future<bool> prepareNewWalletSession(WalletType type) async {
    if (!trezorUseNative.contains(type)) {
      return isConnected(type);
    }
    // Whatever was prepared for a reconnect must not shape a new wallet.
    _presetSettings = null;
    _presetWalletKey = null;

    final ok = await _rebindSession(null);
    if (ok) {
      // Attributed to the new wallet once it has been restored
      // (see [rememberWalletSettings]).
      _sessionWalletKey = null;
    }
    return ok;
  }

  /// Binds a fresh session on the live client. With [preset] nothing is asked
  /// in the app (device mode: the device asks; app mode: silent; none: the
  /// empty passphrase is bound explicitly). Without, the settings sheet asks.
  Future<bool> _rebindSession(TrezorDeviceSettings? preset) async {
    final client = _client;
    if (client == null || client.connection.isDisconnected) {
      return false;
    }
    if (isConnecting) {
      return false;
    }
    isConnecting = true;
    _cancelCompleter = Completer<void>();
    paringState = TrezorParingState.initial;

    return _runWithPairingSheet(
      attempt: () async {
        final passphraseAlwaysOnDevice = client.passphraseAlwaysOnDevice;

        TrezorDeviceSettings settings;
        if (preset != null) {
          settings = preset;
        } else if (passphraseAlwaysOnDevice) {
          // The device asks on its own screen; nothing to choose here.
          settings = const TrezorDeviceSettings(enableAutoParing: false, passphraseOnDevice: true);
        } else {
          paringState = TrezorParingState.awaitingSettings(
            isAutoPairingAvailable: false,
            passphraseAlwaysOnDevice: false,
          );
          _settingsCompleter = Completer<TrezorDeviceSettings>();
          settings = await _untilCancelled(_settingsCompleter!.future);
        }
        _throwIfCancelled();

        settings = await _resolveAppPassphrase(settings);
        final usesPassphrase = settings.usesPassphrase;
        paringState = usesPassphrase || passphraseAlwaysOnDevice
            ? TrezorParingState.awaitingPassphrase
            : TrezorParingState.connecting;
        final passphrase = settings.passphraseOnDevice
            ? const sdk.TrezorPassphrase.onDevice()
            : usesPassphrase
                ? sdk.TrezorPassphrase.value(settings.passphrase ?? "")
                : const sdk.TrezorPassphrase.empty();
        await _untilCancelled(client.createSession(passphrase));
        _throwIfCancelled();

        _sessionSettings = passphraseAlwaysOnDevice && !usesPassphrase
            ? const TrezorDeviceSettings(enableAutoParing: false, passphraseOnDevice: true)
            : _withoutSecret(settings);
      },
      // The link itself is fine; only the session attempt failed.
      onFailure: () async {},
    );
  }

  /// For an app-side passphrase wallet the mode is remembered but never the
  /// secret: ask for it now, for this session only.
  Future<TrezorDeviceSettings> _resolveAppPassphrase(TrezorDeviceSettings settings) async {
    if (!settings.askPassphraseInApp) return settings;

    paringState = TrezorParingState.awaitingAppPassphrase;
    _passphraseCompleter = Completer<String>();
    final passphrase = await _untilCancelled(_passphraseCompleter!.future);
    _throwIfCancelled();
    return settings.withPassphrase(passphrase);
  }

  /// Shows the pairing sheet and runs [attempt] until it succeeds, the user
  /// gives up, or the user exits the sheet. The result reaches the caller even
  /// when success only comes on a retry. Expects [isConnecting] and
  /// [_cancelCompleter] to be set by the caller.
  Future<bool> _runWithPairingSheet({
    required Future<void> Function() attempt,
    required Future<void> Function() onFailure,
  }) async {
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
          await attempt();
          paringState = TrezorParingState.success;
          return true;
        } catch (e) {
          await onFailure();
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
      _passphraseCompleter = null;
      _cancelCompleter = null;
    }
  }

  /// One connection attempt. Throws on any failure; the caller decides whether
  /// to retry.
  Future<void> _connect(TrezorHardwareWalletDevice device, TrezorDeviceSettings? preset) async {
    final trezorInterface =
        device.connectionType == HardwareWalletConnectionType.ble ? trezorBLE : trezorUSB;

    // Serialise behind a previous attempt that was cancelled mid-connect.
    await _awaitPendingCleanup();

    final connection = await _untilCancelled(
      trezorInterface.connect(device.device),
      // A link that comes up after the user gave up must not linger.
      onLateResult: (late) => late.disconnect(),
    );

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
    final hasAutoPairingCredentials = state.pairingCredentials.any((c) => c.autoconnect == true);

    // First pairing walks the user through the device's pairing dialogs and
    // ends in the code entry; later connects are silent unless the device asks
    // for the passphrase itself.
    paringState = hasAutoPairingCredentials
        ? TrezorParingState.connecting
        : TrezorParingState.pairingOnDevice;
    await _untilCancelled(client.createChannel());
    final isAutoPairingAvailable = client is sdk.TrezorClientV2 && !hasAutoPairingCredentials;

    // With "passphrase always on device" enabled the device already asked for
    // the passphrase while the channel (and its initial session) was created,
    // so the session is bound to what the user entered there. Asking in the
    // app or creating a second session would only prompt them a second time.
    final passphraseAlwaysOnDevice = client.passphraseAlwaysOnDevice;

    TrezorDeviceSettings settings;
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
      settings = await _untilCancelled(_settingsCompleter!.future);
    }
    _throwIfCancelled();

    if (settings.enableAutoParing && isAutoPairingAvailable) {
      if (client case final sdk.TrezorClientV2 clientV2) {
        try {
          paringState = TrezorParingState.awaitingAutoConnectConfirm;
          final auto = await _untilCancelled(clientV2.getAutoPairingCredentials());
          state.setPairingCredentials([auto]);
          await _saveState();
        } on _PairingCancelledException {
          rethrow;
        } catch (e) {
          // Auto-pairing is a convenience; the connection is still usable.
          printV(e);
        }
      }
    }
    _throwIfCancelled();

    settings = await _resolveAppPassphrase(settings);
    final usesPassphrase = settings.usesPassphrase;
    if (usesPassphrase && !passphraseAlwaysOnDevice) {
      paringState = TrezorParingState.awaitingPassphrase;
      final passphrase = settings.passphraseOnDevice
          ? const sdk.TrezorPassphrase.onDevice()
          : sdk.TrezorPassphrase.value(settings.passphrase ?? "");
      await _untilCancelled(client.createSession(passphrase));
    } else {
      paringState = TrezorParingState.connecting;
    }
    _throwIfCancelled();

    // Remember what the wallet was set up with. A settings object that already
    // carries a passphrase choice (on-device, or an app-side value) is kept as
    // is even when the device currently forces on-device entry, so a stored
    // app-side passphrase is not silently discarded and still applies if that
    // device option is turned off later. Only when there was nothing to choose
    // (options hidden) do we record "device" mode, which is the safe default.
    _sessionSettings = passphraseAlwaysOnDevice && !usesPassphrase
        ? TrezorDeviceSettings(
            enableAutoParing: settings.enableAutoParing,
            passphraseOnDevice: true,
          )
        : _withoutSecret(settings);
  }

  /// Keeps only the mode of [settings]; the typed passphrase is dropped once
  /// the session is bound so nothing retains it.
  TrezorDeviceSettings _withoutSecret(TrezorDeviceSettings settings) => TrezorDeviceSettings(
        enableAutoParing: settings.enableAutoParing,
        passphraseOnDevice: settings.passphraseOnDevice,
        askPassphraseInApp: !settings.passphraseOnDevice &&
            (settings.askPassphraseInApp || (settings.passphrase ?? "").isNotEmpty),
      );

  Future<void> _resetClient() async {
    try {
      await _client?.connection.disconnect();
    } catch (e) {
      printV(e);
    }
    _client = null;
    _sessionSettings = null;
    _sessionWalletKey = null;
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

    _presetSettings = await _walletSettings.load(wallet.type, wallet.name);
    _presetWalletKey = _walletKey(wallet);
  }

  @override
  Future<void> rememberWalletSettings(WalletBase wallet) async {
    final settings = _sessionSettings;
    if (settings == null || !_usesPersistedSettings(wallet)) return;

    final key = _walletKey(wallet);
    // Never persist a session that belongs to a different wallet.
    if (_sessionWalletKey != null && _sessionWalletKey != key) return;

    _sessionWalletKey = key;
    await _walletSettings.save(wallet.type, wallet.name, settings);
  }

  /// Makes sure the live session belongs to [wallet] before it is used for
  /// signing or key-image sync. A session opened for another wallet is rebound
  /// with this wallet's own settings: silently when they are stored, otherwise
  /// the settings sheet asks.
  Future<void> _ensureSessionFor(WalletBase wallet) async {
    if (!_usesPersistedSettings(wallet)) return;

    final key = _walletKey(wallet);
    // A session that is not attributed to this wallet (another wallet's, or
    // one left over from an abandoned restore) must be rebound first.
    if (_sessionWalletKey != key) {
      final stored = await _walletSettings.load(wallet.type, wallet.name);
      if (!await _rebindSession(stored)) {
        throw TrezorSessionMismatchException(wallet.name);
      }
      _sessionWalletKey = null;
    }

    // Stored settings can be wrong (e.g. recorded as "no passphrase" for a
    // passphrase wallet). Check the session actually derives this wallet's
    // keys; if not, ask for the passphrase once and check again, rather than
    // failing later with a script/pubkey mismatch at signing time.
    if (!await _sessionMatchesWallet(wallet)) {
      _sessionWalletKey = null;
      if (!await _rebindSession(null) || !await _sessionMatchesWallet(wallet)) {
        throw TrezorSessionMismatchException(wallet.name);
      }
    }

    await rememberWalletSettings(wallet);
  }

  Future<bool> _sessionMatchesWallet(WalletBase wallet) async {
    final client = _client;
    if (client == null) return false;
    try {
      switch (wallet.type) {
        case WalletType.bitcoin:
          return await bitcoin!.trezorSessionMatchesWallet(wallet, client);
        case WalletType.monero:
          return await monero!.trezorSessionMatchesWallet(wallet, client);
        default:
          return true;
      }
    } catch (e) {
      // A failed query is reported as a mismatch so the user gets a prompt
      // instead of a silent wrong-wallet operation.
      printV(e);
      return false;
    }
  }

  bool _usesPersistedSettings(WalletBase wallet) =>
      trezorUseNative.contains(wallet.type) &&
      wallet.hardwareWalletType == HardwareWalletType.trezor;

  String _walletKey(WalletBase wallet) =>
      TrezorWalletSettingsStorage.walletKey(wallet.type, wallet.name);

  @override
  Future<void> initWallet(WalletBase wallet) async {
    await _ensureSessionFor(wallet);

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

  /// Human-readable reason of the last failed [syncKeyImages], if any.
  String? lastSyncError;

  Future<bool> syncKeyImages(WalletBase wallet) async {
    lastSyncError = null;
    if (wallet.type == WalletType.monero) {
      try {
        await monero!.syncTrezor(wallet);
      } catch (e) {
        printV(e);
        lastSyncError = interpretErrorCode(e.toString());
        // A failed device round-trip usually means the link is gone; make the
        // next attempt reconnect cleanly instead of reusing a dead client.
        if (_client?.connection.isDisconnected ?? true) {
          await _resetClient();
        }
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
  static TrezorParingState awaitingAppPassphrase = AwaitingAppPassphraseTrezorParingState();
  static TrezorParingState awaitingAutoConnectConfirm =
      AwaitingAutoConnectConfirmTrezorParingState();
  static TrezorParingState connecting = ConnectingTrezorParingState();
  static TrezorParingState pairingOnDevice = PairingOnDeviceTrezorParingState();

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

/// The live Trezor session belongs to another wallet and could not be rebound
/// to [walletName] (the user cancelled or the device rejected it).
class TrezorSessionMismatchException implements Exception {
  TrezorSessionMismatchException(this.walletName);

  final String walletName;

  @override
  String toString() => S.current.trezor_error_session_mismatch;
}

class AwaitingPassphraseTrezorParingState extends TrezorParingState {}

/// The wallet's passphrase is typed in the app; waiting for the user.
class AwaitingAppPassphraseTrezorParingState extends TrezorParingState {}

/// The device asks whether Cake Wallet may connect automatically in future.
class AwaitingAutoConnectConfirmTrezorParingState extends TrezorParingState {}

/// Link and channel are being set up with stored credentials; nothing to do
/// unless the device itself asks for something.
class ConnectingTrezorParingState extends TrezorParingState {}

/// First pairing: the device walks through its pairing dialogs before showing
/// the security code.
class PairingOnDeviceTrezorParingState extends TrezorParingState {}

class SuccessTrezorParingState extends TrezorParingState {}

class FailTrezorParingState extends TrezorParingState {
  FailTrezorParingState(this.message);

  final String message;
}
