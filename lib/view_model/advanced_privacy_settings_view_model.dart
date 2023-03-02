import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'advanced_privacy_settings_view_model.g.dart';

class AdvancedPrivacySettingsViewModel = AdvancedPrivacySettingsViewModelBase
    with _$AdvancedPrivacySettingsViewModel;

abstract class AdvancedPrivacySettingsViewModelBase with Store {
  AdvancedPrivacySettingsViewModelBase(this.type, this._settingsStore) : _addCustomNode = false;

  @computed
  ExchangeApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  FiatApiMode get fiatApi => _settingsStore.fiatApiMode;

  @observable
  bool _addCustomNode = false;

  final WalletType type;

  final SettingsStore _settingsStore;

  @computed
  bool get addCustomNode => _addCustomNode;

  @action
  void setFiatMode(bool value) {
    if (value) {
      _settingsStore.fiatApiMode = FiatApiMode.disabled;
      return;
    }
    _settingsStore.fiatApiMode = FiatApiMode.enabled;
  }

  @action
  void setExchangeApiMode(ExchangeApiMode value) {
    _settingsStore.exchangeStatus = value;
  }

  @action
  void toggleAddCustomNode() {
    _addCustomNode = !_addCustomNode;
  }
}
