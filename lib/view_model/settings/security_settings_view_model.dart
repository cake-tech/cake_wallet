import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'security_settings_view_model.g.dart';

class SecuritySettingsViewModel = SecuritySettingsViewModelBase with _$SecuritySettingsViewModel;

abstract class SecuritySettingsViewModelBase with Store {
  SecuritySettingsViewModelBase(
    this._settingsStore,
    this._authService,
  ) : _biometricAuth = BiometricAuth();

  final BiometricAuth _biometricAuth;
  final SettingsStore _settingsStore;
  final AuthService _authService;

  @computed
  bool get allowBiometricalAuthentication => _settingsStore.allowBiometricalAuthentication;

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
  setPinCodeRequiredDuration(PinCodeRequiredDuration duration) =>
      _settingsStore.pinTimeOutDuration = duration;

  bool checkPinCodeRiquired() => _authService.requireAuth();
}
