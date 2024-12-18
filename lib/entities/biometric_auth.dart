import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';

class BiometricAuth {
  final _flutterLocalAuthenticationPlugin = FlutterLocalAuthentication();

  Future<bool> isAuthenticated() async {
    try {
      final authenticated = await _flutterLocalAuthenticationPlugin.authenticate();
      return authenticated;
    } catch (e) {
      printV(e);
    }
    return false;
  }

  Future<bool> canCheckBiometrics() async {
    bool canAuthenticate;
    try {
      canAuthenticate = await _flutterLocalAuthenticationPlugin.canAuthenticate();
      await _flutterLocalAuthenticationPlugin.setTouchIDAuthenticationAllowableReuseDuration(0);
    } catch (error) {
      printV("Exception checking support. $error");
      canAuthenticate = false;
    }

    return canAuthenticate;
  }
}