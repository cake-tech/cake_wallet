import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'privacy_settings_view_model.g.dart';

class PrivacySettingsViewModel = PrivacySettingsViewModelBase
    with _$PrivacySettingsViewModel;

abstract class PrivacySettingsViewModelBase with Store {
  PrivacySettingsViewModelBase(this._settingsStore);

  final SettingsStore _settingsStore;

  @computed
  bool get shouldSaveRecipientAddress =>
      _settingsStore.shouldSaveRecipientAddress;

  @action
  void setShouldSaveRecipientAddress(bool value) =>
      _settingsStore.shouldSaveRecipientAddress = value;
}