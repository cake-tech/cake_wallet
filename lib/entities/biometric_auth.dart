import "dart:io";

import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:local_auth/local_auth.dart";

class BiometricDisplayType {

  const BiometricDisplayType._(this.displayName, this.iconPath);

  final String displayName;
  final String iconPath;

  static const faceId = BiometricDisplayType._("Face ID", "assets/new-ui/biometry_icons/faceid.svg");
  static const touchId = BiometricDisplayType._("Touch ID", "assets/new-ui/biometry_icons/touchid.svg");
  // no it can't be S.current since that's initialized late. S.current provides no real advantage since you gotta restart anyway
  static final generic = BiometricDisplayType._(const S().fingerprint_unlock, "assets/new-ui/biometry_icons/generic.svg");
}

class BiometricAuth {
  BiometricAuth() {
    _getDisplayType();
  }

  final _flutterLocalAuthenticationPlugin = LocalAuthentication();

  Future<bool> isAuthenticated() async {
    try {
      return await _flutterLocalAuthenticationPlugin.authenticate(
        options: const AuthenticationOptions(biometricOnly: true),
        authMessages: [],
          localizedReason: S.current.unlock_your_wallet,);
    } catch (e) {
      printV(e);
    }
    return false;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _flutterLocalAuthenticationPlugin.canCheckBiometrics;
    } catch (error) {
      printV("Exception checking support. $error");
      return false;
    }

  }

  BiometricDisplayType? displayType;

    Future<void> _getDisplayType() async {
    final availableBiometrics = await _flutterLocalAuthenticationPlugin.getAvailableBiometrics();

    if(availableBiometrics.isEmpty) {
      displayType = null;
      return;
    }

    if(!Platform.isIOS && !Platform.isMacOS) {
      displayType = BiometricDisplayType.generic;
      return;
    }

    if(availableBiometrics.contains(BiometricType.face)) {
      displayType = BiometricDisplayType.faceId;
    } else {
      displayType = BiometricDisplayType.touchId;
    }
  }
}
