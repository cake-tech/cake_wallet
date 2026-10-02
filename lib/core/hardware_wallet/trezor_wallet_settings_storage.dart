import "package:cake_wallet/core/secure_storage.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";

/// How a Trezor session for a given wallet is set up: whether to fetch
/// auto-pairing credentials and how (if at all) the passphrase is supplied.
class TrezorDeviceSettings {
  const TrezorDeviceSettings({
    required this.enableAutoParing,
    required this.passphraseOnDevice,
    this.passphrase,
    this.askPassphraseInApp = false,
  });

  final bool enableAutoParing;
  final bool passphraseOnDevice;

  /// Passphrase typed in the app for this session only. Never persisted.
  final String? passphrase;

  /// The wallet uses an app-side passphrase that still has to be asked for
  /// (restored settings only remember the mode, not the secret).
  final bool askPassphraseInApp;

  bool get usesPassphrase =>
      passphraseOnDevice || askPassphraseInApp || (passphrase ?? "").isNotEmpty;

  TrezorDeviceSettings withPassphrase(String value) => TrezorDeviceSettings(
        enableAutoParing: enableAutoParing,
        passphraseOnDevice: false,
        passphrase: value,
      );
}

/// Per-wallet persistence of how the Trezor session is set up: whether the
/// wallet has no passphrase, a passphrase entered on the device, or one typed
/// in the app. Only the mode is stored; an app-side passphrase is asked for on
/// every connect and never written anywhere.
///
/// Records are keyed by wallet type and name. They must be removed when the
/// wallet is deleted and moved when it is renamed, or a stale record would
/// outlive its wallet and be applied to a later wallet reusing the name.
class TrezorWalletSettingsStorage {
  TrezorWalletSettingsStorage(this._secureStorage);

  final SecureStorage _secureStorage;

  static const String _modeKeyPrefix = "com.cakewallet.trezor/passphrase_mode/";
  static const String _passphraseKeyPrefix = "com.cakewallet.trezor/passphrase/";
  static const String _modeDevice = "device";
  static const String _modeApp = "app";
  static const String _modeNone = "none";

  static String walletKey(WalletType type, String name) => "${walletTypeToString(type)}_$name";

  Future<TrezorDeviceSettings?> load(WalletType type, String name) async {
    try {
      final key = walletKey(type, name);
      final mode = await _secureStorage.read(key: _modeKeyPrefix + key);

      switch (mode) {
        case _modeDevice:
          return const TrezorDeviceSettings(enableAutoParing: true, passphraseOnDevice: true);
        case _modeApp:
          return const TrezorDeviceSettings(
            enableAutoParing: true,
            passphraseOnDevice: false,
            askPassphraseInApp: true,
          );
        case _modeNone:
          return const TrezorDeviceSettings(enableAutoParing: true, passphraseOnDevice: false);
        default:
          return null;
      }
    } catch (e) {
      printV(e);
      return null;
    }
  }

  Future<void> save(WalletType type, String name, TrezorDeviceSettings settings) async {
    try {
      final key = walletKey(type, name);
      final mode = settings.passphraseOnDevice
          ? _modeDevice
          : settings.askPassphraseInApp || (settings.passphrase ?? "").isNotEmpty
              ? _modeApp
              : _modeNone;

      await _secureStorage.write(key: _modeKeyPrefix + key, value: mode);
      // Earlier builds stored the app-side passphrase itself; scrub it.
      await _secureStorage.delete(key: _passphraseKeyPrefix + key);
    } catch (e) {
      printV(e);
    }
  }

  /// Removes the records of a wallet. Safe to call for wallets that never had
  /// any (non-Trezor wallets included).
  Future<void> delete(WalletType type, String name) async {
    try {
      final key = walletKey(type, name);
      await _secureStorage.delete(key: _modeKeyPrefix + key);
      await _secureStorage.delete(key: _passphraseKeyPrefix + key);
    } catch (e) {
      printV(e);
    }
  }

  /// Moves the records of a wallet to its new name.
  Future<void> rename(WalletType type, String oldName, String newName) async {
    try {
      final oldKey = walletKey(type, oldName);
      final mode = await _secureStorage.read(key: _modeKeyPrefix + oldKey);
      if (mode == null) return;

      final newKey = walletKey(type, newName);
      await _secureStorage.write(key: _modeKeyPrefix + newKey, value: mode);
      await _secureStorage.delete(key: _passphraseKeyPrefix + newKey);
      await delete(type, oldName);
    } catch (e) {
      printV(e);
    }
  }
}
