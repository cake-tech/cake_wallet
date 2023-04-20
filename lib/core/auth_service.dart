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
  ];

  final FlutterSecureStorage secureStorage;
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

  Future<void> authenticateAction(BuildContext context,
      {Function(bool)? onAuthSuccess, String? route, Object? arguments}) async {
    assert(route != null || onAuthSuccess != null,
        'Either route or onAuthSuccess param must be passed.');
    if (!requireAuth() && !_alwaysAuthenticateRoutes.contains(route)) {
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
    Navigator.of(context).pushNamed(Routes.auth,
        arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
      if (!isAuthenticatedSuccessfully) {
        onAuthSuccess?.call(false);
        return;
      }
      if (onAuthSuccess != null) {
        auth.close().then((value) => onAuthSuccess.call(true));
      } else {
        auth.close(route: route, arguments: arguments);
      }
    });
  }
}
