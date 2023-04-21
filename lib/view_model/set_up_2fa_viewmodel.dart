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

  String _randomBase32Key = '';
  String get secretKey => _randomBase32Key;
  String get deviceName => _settingsStore.deviceName;

  @computed
  bool get useTOTP2FA => _settingsStore.useTOTP2FA;

  void getRandomBase32SecretKey() {
    _randomBase32Key = Utils.generateRandomBase32SecretKey(16);
  }

  @action
  void setUseTOTP2FA(bool value) => _settingsStore.useTOTP2FA = value;
}
