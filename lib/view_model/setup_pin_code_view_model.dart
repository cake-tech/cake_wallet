import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/store/settings_store.dart';

class SetupPinCodeViewModel {
  SetupPinCodeViewModel(this._authService, this._settingsStore,
      {this.isDuressPin = false})
      : _pinCodeLength = _settingsStore.pinCodeLength;

  String originalPinCode = '';

  String repeatedPinCode = '';

  Future<void> setPinCode(String pinCode) async {
    if (!isOriginalPinCodeFull) {
      await setOriginalPinCode(pinCode);
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
  final bool isDuressPin;
  int _pinCodeLength;

  Future<void> setOriginalPinCode(String pin) async {
    originalPinCode = pin;

    if (isDuressPin && pin.length == pinCodeLength) {

      final regularKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
      final encodedRegularPin = await _authService.secureStorage.read(key: regularKey);

      if (encodedRegularPin != null && encodedRegularPin.isNotEmpty) {
        final realPin = decodedPinCode(pin: encodedRegularPin);

        if (pin == realPin) {
          reset();
          throw Exception('Duress PIN cannot be the same as regular PIN');
        }
      }
    }
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

    if (isDuressPin) {
      await _authService.setDuressPin(repeatedPinCode);
      return;
    }


    await _authService.setPassword(repeatedPinCode);
    _settingsStore.pinCodeLength = pinCodeLength;
  }
}
