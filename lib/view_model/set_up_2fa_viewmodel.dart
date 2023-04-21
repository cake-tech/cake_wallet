// ignore_for_file: prefer_final_fields

import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/totp_utils.dart' as Utils;

class Setup2FAViewModel {
  final SettingsStore _settingsStore;

  Setup2FAViewModel(this._settingsStore) {
    getRandomBase32SecretKey();
  }

  String get deviceName => _settingsStore.deviceName;

  String _randomBase32Key = '';
  String get secretKey => _randomBase32Key;

  void getRandomBase32SecretKey() {
    _randomBase32Key = Utils.generateRandomBase32SecretKey(16);
  }
}
