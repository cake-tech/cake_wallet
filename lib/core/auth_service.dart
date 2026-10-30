import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/core/reset_service.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/store/app_store.dart' show AppStore;
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cw_core/db/sqlite.dart';
import "package:cw_core/keychain_read_status_native.dart";
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import "package:cw_core/wallet_group_db_entry.dart";
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:cake_wallet/store/settings_store.dart';
import '../src/screens/setup_2fa/setup_2fa_enter_code_page.dart';

class AuthService with Store {
  AuthService({
    required this.secureStorage,
    required this.sharedPreferences,
    required this.settingsStore,
    required this.authenticationStore,
    required this.appStore,
    required this.resetService,
    required this.walletList,
  });

  static const List<String> _alwaysAuthenticateRoutes = [
    Routes.showKeys,
    Routes.seed,
    Routes.backup,
    Routes.setupPin,
    Routes.setup_2faPage,
    Routes.modify2FAPage,
    Routes.newWallet,
    Routes.walletCreationTypeSelectionPage,
    Routes.addressBookAddContact,
    Routes.restoreOptions,
    Routes.securityBackupDuressPin,
  ];

  final SecureStorage secureStorage;
  final SharedPreferences sharedPreferences;
  final SettingsStore settingsStore;
  final AuthenticationStore authenticationStore;
  final AppStore appStore;
  final ResetService resetService;
  final List<WalletInfo> walletList;

  Future<void> setPassword(String password) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPassword = encodedPinCode(pin: password);
    await secureStorage.write(key: key, value: encodedPassword);
  }

  Future<void> setDuressPin(String pin) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.duressPinCodePassword);
    final encodedPin = encodedPinCode(pin: pin);
    await secureStorage.write(key: key, value: encodedPin);
  }

  Future<void> clearDuressPin() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.duressPinCodePassword);
    await secureStorage.delete(key: key);
  }

  Future<bool> canAuthenticate() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final walletName = sharedPreferences.getString(PreferencesKey.currentWalletName) ?? '';
    var password = '';

    try {
      password = await secureStorage.read(key: key) ?? '';
    } catch (e) {
      printV(e);
    }

    return walletName.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> authenticate(String pin) async {
    final regularKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedRegularPin = await secureStorage.read(key: regularKey);
    if (encodedRegularPin == null) {
      throw PinCodeUnreadableException(await keychainReadStatusNative(regularKey));
    }

    final decodedRegularPin = decodedPinCode(pin: encodedRegularPin);

    if (decodedRegularPin == pin) {
      return true;
    }

    // Check for duress pin
    final duressKey = generateStoreKeyFor(key: SecretStoreKey.duressPinCodePassword);
    final encodedDuressPin = await secureStorage.read(key: duressKey);

    String? decodedDuressPin;
    if (encodedDuressPin != null && encodedDuressPin.isNotEmpty) {
      try {
        decodedDuressPin = decodedPinCode(pin: encodedDuressPin);
      } catch (e) {
        printV("Failed to decode duress pin: $e");
      }
    }

    if (decodedDuressPin == pin) {
      await _handleDuressLogin(secureStorage, sharedPreferences, authenticationStore, appStore,
          resetService, walletList);

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.welcome,
        (route) => false,
      );

      return false;
    }
    return false;
  }

  /// iOS only: true when this device has neither the stored PIN nor any wallet password, e.g. an
  /// iCloud Backup restored onto a new device brings the app's data but never its Keychain. Then no
  /// PIN can be checked and no wallet decrypted here. Never throws.
  Future<bool> isKeychainNotRestored() async {
    try {
      return await keychainSecretsMissing(
        readStatus: keychainReadStatusNative,
        walletNames: () async {
          final currentWalletName = sharedPreferences.getString(PreferencesKey.currentWalletName);
          return {
            for (final walletInfo in await WalletInfo.getAll()) walletInfo.name,
            if (currentWalletName != null && currentWalletName.isNotEmpty) currentWalletName,
          };
        },
      );
    } catch (e) {
      printV("Keychain restore check failed: $e");
      return false;
    }
  }

  /// Starts over when [isKeychainNotRestored]: removes the wallets this device can't open, with the
  /// same wipe as the duress PIN, then opens the welcome screen so they can be restored.
  Future<void> resetAfterKeychainLoss() async {
    if (!await isKeychainNotRestored()) {
      return;
    }

    await _handleDuressLogin(
      secureStorage,
      sharedPreferences,
      authenticationStore,
      appStore,
      resetService,
      walletList,
    );

    unawaited(
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.welcome,
        (route) => false,
      ),
    );
  }

  void saveLastAuthTime() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    secureStorage.write(key: SecureKey.lastAuthTimeMilliseconds, value: timestamp.toString());
  }

  Future<bool> requireAuth() async {
    try {
      final timestamp =
          int.tryParse(await secureStorage.read(key: SecureKey.lastAuthTimeMilliseconds) ?? '0');
      final duration = _durationToRequireAuth(timestamp ?? 0);
      final requiredPinInterval = settingsStore.pinTimeOutDuration;

      return duration >= requiredPinInterval.value;
    } catch (e) {
      // Without the last auth time we can't tell if the timeout passed, so ask for the PIN.
      printV(e);
      return true;
    }
  }

  int _durationToRequireAuth(int timestamp) {
    DateTime before = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration timeDifference = now.difference(before);

    return timeDifference.inMinutes;
  }

  Future<void> authenticateAction(BuildContext context,
      {Function(bool)? onAuthSuccess,
      String? route,
      Object? arguments,
      required bool conditionToDetermineIfToUse2FA}) async {
    assert(route != null || onAuthSuccess != null,
        'Either route or onAuthSuccess param must be passed.');

    if (!conditionToDetermineIfToUse2FA) {
      if (!(await requireAuth()) && !_alwaysAuthenticateRoutes.contains(route)) {
        if (onAuthSuccess != null) {
          onAuthSuccess(true);
        } else {
          Navigator.of(context).pushNamed(
            route ?? '',
            arguments: arguments,
          );
        }
        return;
      }
    }

    if (context.mounted) {
      Navigator.of(context).pushNamed(Routes.auth,
          arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
        if (!isAuthenticatedSuccessfully) {
          onAuthSuccess?.call(false);
          return;
        } else {
          if (settingsStore.useTOTP2FA && conditionToDetermineIfToUse2FA) {
            auth.close(
              route: Routes.totpAuthCodePage,
              arguments: TotpAuthArgumentsModel(
                isForSetup: !settingsStore.useTOTP2FA,
                onTotpAuthenticationFinished:
                    (bool isAuthenticatedSuccessfully, TotpAuthCodePageState totpAuth) async {
                  if (!isAuthenticatedSuccessfully) {
                    onAuthSuccess?.call(false);
                    return;
                  }
                  if (onAuthSuccess != null) {
                    totpAuth.close().then((value) => onAuthSuccess.call(true));
                  } else {
                    totpAuth.close(route: route, arguments: arguments);
                  }
                },
              ),
            );
          } else {
            if (onAuthSuccess != null) {
              auth.close().then((value) => onAuthSuccess.call(true));
            } else {
              auth.close(route: route, arguments: arguments);
            }
          }
        }
      });
    }
  }
}

Future<void> _handleDuressLogin(
  SecureStorage secureStorage,
  SharedPreferences sharedPreferences,
  AuthenticationStore authenticationStore,
  AppStore appStore,
  ResetService resetService,
  List<WalletInfo> wallets,
) async {
  printV('[DURESS] START FULL WIPE PROCESS');

  // Close wallet instance if opened
  try {
    if (appStore.wallet != null) {
      await appStore.wallet!.close();
    }
    appStore.wallet = null;
  } catch (e) {
    printV('[DURESS] Failed to close wallet instance: $e');
  }

  // Reset shared preference flag for new install
  try {
    await sharedPreferences.setBool(PreferencesKey.isNewInstall, true);
    printV('[DURESS] isNewInstall flag set to true');
  } catch (e) {
    printV('[DURESS] Failed to set isNewInstall: $e');
  }

  // Reset auth data
  await resetService.resetAuthDataOnNewInstall(sharedPreferences);
  printV('[DURESS] Authentication data reset');

  // wipe secure storage
  try {
    await secureStorage.deleteAll();
    printV('[DURESS] SecureStorage wiped');
  } catch (e) {
    printV('[DURESS] SecureStorage wipe failed: $e');
  }

  // Delete wallet directories
  try {
    final appDir = await getAppDir();
    final walletsDir = Directory('${appDir.path}/wallets');

    if (walletsDir.existsSync()) {
      walletsDir.deleteSync(recursive: true);
      printV('[DURESS] Wallet directories deleted');
    }
  } catch (e) {
    printV('[DURESS] Failed deleting wallet directories: $e');
  }

  // Wipe wallet-related database tables
  try {
    await db!.transaction((txn) async {
      await txn.delete(WalletInfoAddressInfo.tableName);
      await txn.delete(WalletInfoAddressMap.tableName);
      await txn.delete(WalletInfoAddress.tableName);
      await txn.delete(DerivationInfo.tableName);
      await txn.delete(WalletGroupDbEntry.tableName);
      await txn.delete(WalletInfo.tableName);
    });
    printV('[DURESS] SQLite wallet tables wiped');
  } catch (e) {
    printV('[DURESS] SQLite wipe failed: $e');
  }

  //Force app state to uninitialized
  authenticationStore.state = AuthenticationState.uninitialized;
  printV('[DURESS] Authentication state set to "uninitialized"');

  printV('[DURESS] FULL WIPE COMPLETED');
}

/// Thrown by [AuthService.authenticate] when secure storage returns no stored PIN.
class PinCodeUnreadableException implements Exception {
  PinCodeUnreadableException(this.keychainStatus);

  /// iOS Keychain OSStatus of the same read (e.g. -25300 not found, -25308 locked); null on
  /// other platforms or when it couldn't be fetched.
  final int? keychainStatus;

  @override
  String toString() {
    final status = keychainStatus == null ? "" : " (Keychain OSStatus: $keychainStatus)";
    return "PinCodeUnreadableException: secure storage returned no PIN$status";
  }
}

/// errSecItemNotFound: the Keychain has no item for the key (not merely locked).
const _errSecItemNotFound = -25300;

/// True only when [readStatus] reports the stored PIN and the password of every wallet in
/// [walletNames] as missing (errSecItemNotFound). A null status (no Keychain status on this
/// platform) never counts as missing, and wallet names are only loaded once the PIN is missing.
Future<bool> keychainSecretsMissing({
  required Future<int?> Function(String key) readStatus,
  required Future<Iterable<String>> Function() walletNames,
}) async {
  final pinKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
  if (await readStatus(pinKey) != _errSecItemNotFound) {
    return false;
  }

  final names = await walletNames();
  if (names.isEmpty) {
    return false;
  }

  for (final name in names) {
    final passwordKey =
        generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: name);
    if (await readStatus(passwordKey) != _errSecItemNotFound) {
      return false;
    }
  }

  return true;
}
