import 'dart:io';

import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  ];

  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;
  final SettingsStore settingsStore;

  Future<void> setPassword(String password) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPassword = encodedPinCode(pin: password);
    // secure storage has a weird bug on macOS, where overwriting a key doesn't work, unless
    // we delete what's there first:
    if (Platform.isMacOS) {
      await secureStorage.delete(key: key);
    }
    await secureStorage.write(key: key, value: encodedPassword);
  }

  Future<bool> canAuthenticate() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final walletName = sharedPreferences.getString(PreferencesKey.currentWalletName) ?? '';
    var password = '';

    try {
      password = await secureStorage.read(key: key) ?? '';
    } catch (e) {
      print(e);
    }

    return walletName.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> authenticate(String pin) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPin = await secureStorage.read(key: key);
    final decodedPin = decodedPinCode(pin: encodedPin!);

    return decodedPin == pin;
  }

  void saveLastAuthTime() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    secureStorage.write(key: SecureKey.lastAuthTimeMilliseconds, value: timestamp.toString());
  }

  Future<bool> requireAuth() async {
    final timestamp = int.tryParse(await secureStorage.read(key: SecureKey.lastAuthTimeMilliseconds) ?? '0');
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
