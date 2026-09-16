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
  });

  final bool enableAutoParing;
  final bool passphraseOnDevice;
  final String? passphrase;

  bool get usesPassphrase => passphraseOnDevice || (passphrase ?? "").isNotEmpty;
}

/// Per-wallet persistence of [TrezorDeviceSettings] so a reconnect for a known
/// wallet does not have to ask for the passphrase in the app again.
///
/// Records are keyed by wallet type and name. They must be removed when the
/// wallet is deleted and moved when it is renamed, or a stale record (which may
/// hold an app-side passphrase) would outlive its wallet and be applied to a
/// later wallet that happens to get the same name.
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
          final passphrase = await _secureStorage.read(key: _passphraseKeyPrefix + key);
          // Without the stored secret the session cannot be rebuilt silently,
          // so fall back to asking.
          if (passphrase == null || passphrase.isEmpty) return null;

          return TrezorDeviceSettings(
            enableAutoParing: true,
            passphraseOnDevice: false,
            passphrase: passphrase,
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
      final passphrase = settings.passphrase ?? "";
      final mode = settings.passphraseOnDevice
          ? _modeDevice
          : passphrase.isNotEmpty
              ? _modeApp
              : _modeNone;

      await _secureStorage.write(key: _modeKeyPrefix + key, value: mode);
      if (mode == _modeApp) {
        await _secureStorage.write(key: _passphraseKeyPrefix + key, value: passphrase);
      } else {
        await _secureStorage.delete(key: _passphraseKeyPrefix + key);
      }
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
      final passphrase = await _secureStorage.read(key: _passphraseKeyPrefix + oldKey);

      final newKey = walletKey(type, newName);
      await _secureStorage.write(key: _modeKeyPrefix + newKey, value: mode);
      if (passphrase != null) {
        await _secureStorage.write(key: _passphraseKeyPrefix + newKey, value: passphrase);
      } else {
        await _secureStorage.delete(key: _passphraseKeyPrefix + newKey);
      }
      await delete(type, oldName);
    } catch (e) {
      printV(e);
    }
  }
}
