import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';

class BiometricAuth {

  Future<bool> isAuthenticated() async {
    final LocalAuthentication _localAuth = LocalAuthentication();

    try {
      return await _localAuth.authenticateWithBiometrics(
          localizedReason: S.current.biometric_auth_reason,
          useErrorDialogs: true,
          stickyAuth: false
      );
    } on PlatformException
    catch(e) {
      print(e);
    }

    return false;
  }

}