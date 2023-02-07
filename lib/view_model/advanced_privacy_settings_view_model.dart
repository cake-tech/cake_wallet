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
  FiatApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  FiatApiMode get fiatApi => _settingsStore.fiatApiMode;

  @observable
  bool _addCustomNode = false;

  final WalletType type;

  final SettingsStore _settingsStore;

  @computed
  bool get addCustomNode => _addCustomNode;

  @action
  void setFiatMode(FiatApiMode value) {
    _settingsStore.fiatApiMode = value;
  }

  @action
  void setEnableExchange(FiatApiMode value) {
    _settingsStore.exchangeStatus = value;
  }

  @action
  void toggleAddCustomNode() {
    _addCustomNode = !_addCustomNode;
  }
}
