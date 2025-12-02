import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'security_settings_view_model.g.dart';

class SecuritySettingsViewModel = SecuritySettingsViewModelBase with _$SecuritySettingsViewModel;

abstract class SecuritySettingsViewModelBase with Store {
  SecuritySettingsViewModelBase(this._settingsStore, this._authService) : _biometricAuth = BiometricAuth();

  final BiometricAuth _biometricAuth;
  final SettingsStore _settingsStore;
  final AuthService _authService;

  @computed
  bool get allowBiometricalAuthentication => _settingsStore.allowBiometricalAuthentication;

  @computed
  bool get enableDuressPin => _settingsStore.enableDuressPin;

  @computed
  bool get useTotp2FA => _settingsStore.useTOTP2FA;

  @computed
  bool get shouldRequireTOTP2FAForAllSecurityAndBackupSettings =>
      _settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings;

  @computed
  PinCodeRequiredDuration get pinCodeRequiredDuration => _settingsStore.pinTimeOutDuration;

  @action
  Future<bool> biometricAuthenticated() async {
    return await _biometricAuth.canCheckBiometrics() && await _biometricAuth.isAuthenticated();
  }

  @action
  void setAllowBiometricalAuthentication(bool value) =>
      _settingsStore.allowBiometricalAuthentication = value;

  @action
  void setPinCodeRequiredDuration(PinCodeRequiredDuration duration) =>
      _settingsStore.pinTimeOutDuration = duration;

  @action
  void setEnableDuressPin(bool value) =>
      _settingsStore.enableDuressPin = value;

  Future<void> clearDuressPin() async => await _authService.clearDuressPin();

}
