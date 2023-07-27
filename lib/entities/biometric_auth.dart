import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';

class BiometricAuth {
  final _localAuth = LocalAuthentication();

  Future<bool> isAuthenticated() async {
    try {
      return await _localAuth.authenticate(
          localizedReason: S.current.biometric_auth_reason,
          options: AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: false));
    } on PlatformException catch (e) {
      print(e);
    }

    return false;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    return false;
  }
}
