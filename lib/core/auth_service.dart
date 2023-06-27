import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/secure_storage.dart';
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
  ];

  final SecureStorage secureStorage;
  final SharedPreferences sharedPreferences;
  final SettingsStore settingsStore;

  Future<void> setPassword(String password) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPassword = encodedPinCode(pin: password);
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
    sharedPreferences.setInt(PreferencesKey.lastAuthTimeMilliseconds, timestamp);
  }

  bool requireAuth() {
    final timestamp = sharedPreferences.getInt(PreferencesKey.lastAuthTimeMilliseconds);
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

  Future<void> onAuthSuccess(
      bool isAuthenticatedSuccessfully, AuthPageState auth,
      {Function(bool)? onAuthAndTotpSuccess,
      String? route,
      Object? arguments}) async {
    if (!isAuthenticatedSuccessfully) {
      onAuthAndTotpSuccess?.call(false);
      return;
    }

    if (settingsStore.useTOTP2FA) {
      auth.close(
        route: Routes.totpAuthCodePage,
        arguments: TotpAuthArgumentsModel(
          isForSetup: !settingsStore.useTOTP2FA,
          onTotpAuthenticationFinished: (bool isAuthenticatedSuccessfully,
              TotpAuthCodePageState totpAuth) async {
            if (!isAuthenticatedSuccessfully) {
              onAuthAndTotpSuccess?.call(false);
              return;
            }

            if (onAuthAndTotpSuccess != null) {
              totpAuth.close().then((value) => onAuthAndTotpSuccess.call(true));
            } else {
              totpAuth.close(route: route, arguments: arguments);
            }
          },
        ),
      );

      return;
    }

    if (onAuthAndTotpSuccess != null) {
      auth.close().then((value) => onAuthAndTotpSuccess.call(true));
    } else {
      auth.close(route: route, arguments: arguments);
    }
  }

  Future<void> authenticateAction(BuildContext context,
      {Function(bool)? onAuthAndTotpSuccess,
      String? authRoute,
      Object? authArguments,
      String? route,
      Object? arguments,
      bool? alwaysRequireAuth}) async {
    assert(route != null || onAuthAndTotpSuccess != null,
        'Either route or onAuthSuccess param must be passed.');

    if (alwaysRequireAuth != true &&
        !requireAuth() &&
        !_alwaysAuthenticateRoutes.contains(route)) {
      if (onAuthAndTotpSuccess != null) {
        onAuthAndTotpSuccess(true);
      } else {
        Navigator.of(context).pushNamed(
          route ?? '',
          arguments: arguments,
        );
      }
      return;
    }

    Navigator.of(context).pushNamed(authRoute ?? Routes.auth,
        arguments: authArguments ??
            (bool isAuthenticatedSuccessfully, AuthPageState auth) =>
                onAuthSuccess(isAuthenticatedSuccessfully, auth,
                    onAuthAndTotpSuccess: onAuthAndTotpSuccess,
                    route: route,
                    arguments: arguments));
  }
}
