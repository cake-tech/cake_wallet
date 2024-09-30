import 'package:cake_wallet/entities/automatic_backup_mode.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:file_picker/file_picker.dart';

part 'security_settings_view_model.g.dart';

class SecuritySettingsViewModel = SecuritySettingsViewModelBase with _$SecuritySettingsViewModel;

abstract class SecuritySettingsViewModelBase with Store {
  SecuritySettingsViewModelBase(this._settingsStore) : _biometricAuth = BiometricAuth();

  final BiometricAuth _biometricAuth;
  final SettingsStore _settingsStore;

  @computed
  bool get allowBiometricalAuthentication => _settingsStore.allowBiometricalAuthentication;

  @computed
  bool get useTotp2FA => _settingsStore.useTOTP2FA;

  @computed
  bool get shouldRequireTOTP2FAForAllSecurityAndBackupSettings =>
      _settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings;

  @computed
  PinCodeRequiredDuration get pinCodeRequiredDuration => _settingsStore.pinTimeOutDuration;

  @computed
  AutomaticBackupMode get autoBackupMode => _settingsStore.autoBackupMode;

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
  void setAutomaticBackupMode(AutomaticBackupMode mode) => _settingsStore.autoBackupMode = mode;

  @action
  Future<void> pickAutomaticBackupsDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _settingsStore.autoBackupDir = selectedDirectory;
      print(selectedDirectory);
    }
  }
}
