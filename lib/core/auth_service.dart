import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/core/reset_service.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/store/app_store.dart' show AppStore;
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
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
    Routes.backup,
    Routes.setupPin,
    Routes.setup_2faPage,
    Routes.modify2FAPage,
    Routes.newWallet,
    Routes.newWalletType,
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

  Future<bool> authenticate(String pin, BuildContext context) async {
    final regularKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedRegularPin = await secureStorage.read(key: regularKey);
    final decodedRegularPin = decodedPinCode(pin: encodedRegularPin!);

    if (decodedRegularPin == pin) {
      return true;
    }

    // Check for duress pin
    final duressKey =
    generateStoreKeyFor(key: SecretStoreKey.duressPinCodePassword);
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
      await _handleDuressLogin(secureStorage, sharedPreferences,
          authenticationStore, appStore, resetService, walletList);

      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.welcome,
            (route) => false,
      );

      return false;
    }
    return false;
  }

  void saveLastAuthTime() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    secureStorage.write(key: SecureKey.lastAuthTimeMilliseconds, value: timestamp.toString());
  }

  Future<bool> requireAuth() async {
    final timestamp =
        int.tryParse(await secureStorage.read(key: SecureKey.lastAuthTimeMilliseconds) ?? '0');
    final duration = _durationToRequireAuth(timestamp ?? 0);
    final requiredPinInterval = settingsStore.pinTimeOutDuration;

    return duration >= requiredPinInterval.value;
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
    await db.transaction((txn) async {
      await txn.delete(WalletInfoAddressInfo.tableName);
      await txn.delete(WalletInfoAddressMap.tableName);
      await txn.delete(WalletInfoAddress.tableName);
      await txn.delete(DerivationInfo.tableName);
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

