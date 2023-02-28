import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';

part 'privacy_settings_view_model.g.dart';

class PrivacySettingsViewModel = PrivacySettingsViewModelBase with _$PrivacySettingsViewModel;

abstract class PrivacySettingsViewModelBase with Store {
  PrivacySettingsViewModelBase(this._settingsStore);

  final SettingsStore _settingsStore;

  @computed
  bool get disableExchange => _settingsStore.disableExchange;

  @computed
  bool get shouldSaveRecipientAddress => _settingsStore.shouldSaveRecipientAddress;

  @computed
  FiatApiMode get fiatApiMode => _settingsStore.fiatApiMode;

  @action
  void setShouldSaveRecipientAddress(bool value) => _settingsStore.shouldSaveRecipientAddress = value;

  @action
  void setEnableExchange(bool value) => _settingsStore.disableExchange = value;

  @action
  void setFiatMode(FiatApiMode fiatApiMode) => _settingsStore.fiatApiMode = fiatApiMode;

}
