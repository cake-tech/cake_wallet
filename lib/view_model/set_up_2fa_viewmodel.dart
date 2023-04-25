// ignore_for_file: prefer_final_fields

import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/totp_utils.dart' as Utils;
import 'package:mobx/mobx.dart';

part 'set_up_2fa_viewmodel.g.dart';

class Setup2FAViewModel = Setup2FAViewModelBase with _$Setup2FAViewModel;

abstract class Setup2FAViewModelBase with Store {
  final SettingsStore _settingsStore;

  Setup2FAViewModelBase(this._settingsStore) {
    getRandomBase32SecretKey();
  }

  String get secretKey => _settingsStore.totpSecretKey;
  String get deviceName => _settingsStore.deviceName;

  @computed
  bool get useTOTP2FA => _settingsStore.useTOTP2FA;

  void getRandomBase32SecretKey() {
    final randomBase32Key = Utils.generateRandomBase32SecretKey(16);
    setBase32SecretKey(randomBase32Key);
  }

  @action
  void setUseTOTP2FA(bool value) => _settingsStore.useTOTP2FA = value;

  @action
  void setBase32SecretKey(String value) {
    if (_settingsStore.totpSecretKey == '') {
      _settingsStore.totpSecretKey = value;
    }
  }

  @action
  void clearBase32SecretKey() {
    _settingsStore.totpSecretKey = '';
  }
}
