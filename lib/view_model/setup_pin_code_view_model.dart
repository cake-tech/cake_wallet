import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/store/settings_store.dart';

class SetupPinCodeViewModel {
  SetupPinCodeViewModel(this._authService, this._settingsStore)
      : _pinCodeLength = _settingsStore.pinCodeLength;

  String originalPinCode = '';

  String repeatedPinCode = '';

  set pinCode(String pinCode) {
    if (!isOriginalPinCodeFull) {
      setOriginalPinCode(pinCode);
      return;
    }

    repeatedPinCode = pinCode;
  }

  int get pinCodeLength => _pinCodeLength;

  set pinCodeLength(int length) {
    _pinCodeLength = length;
    reset();
  }

  bool get isOriginalPinCodeFull => originalPinCode.length == pinCodeLength;

  bool get isRepeatedPinCodeFull => repeatedPinCode.length == pinCodeLength;

  bool get isPinCodeCorrect =>
      originalPinCode.length == pinCodeLength &&
      repeatedPinCode.length == pinCodeLength &&
      originalPinCode == repeatedPinCode;

  final SettingsStore _settingsStore;
  final AuthService _authService;
  int _pinCodeLength;

  void setOriginalPinCode(String pinCode) {
    if (isOriginalPinCodeFull) {
      return;
    }

    originalPinCode = pinCode;
  }

  void setRepeatedPinCode(String pinCode) {
    if (isRepeatedPinCodeFull) {
      return;
    }

    repeatedPinCode = pinCode;
  }

  void reset() {
    originalPinCode = '';
    repeatedPinCode = '';
  }

  Future<void> setupPinCode() async {
    if (!isPinCodeCorrect) {
      return;
    }

    await _authService.setPassword(repeatedPinCode);
    _settingsStore.pinCodeLength = pinCodeLength;
  }
}
