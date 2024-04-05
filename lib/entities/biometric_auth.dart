// import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';

class BiometricAuth {
  final _flutterLocalAuthenticationPlugin = FlutterLocalAuthentication();

  Future<bool> isAuthenticated() async {
    try {
      final authenticated = await _flutterLocalAuthenticationPlugin.authenticate();
      return authenticated;
    } on PlatformException catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> canCheckBiometrics() async {
    bool canAuthenticate;
    try {
      canAuthenticate = await _flutterLocalAuthenticationPlugin.canAuthenticate();

      // Setup TouchID Allowable Reuse duration
      // It works only in iOS and macOS, but it's safe to call it even on other platforms.
      await _flutterLocalAuthenticationPlugin.setTouchIDAuthenticationAllowableReuseDuration(30);
    } on Exception catch (error) {
      print("Exception checking support. $error");
      canAuthenticate = false;
    }

    return canAuthenticate;
  }
}
