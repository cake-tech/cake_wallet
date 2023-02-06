import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:cake_wallet/view_model/settings/switcher_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'advanced_privacy_settings_view_model.g.dart';

class AdvancedPrivacySettingsViewModel = AdvancedPrivacySettingsViewModelBase
    with _$AdvancedPrivacySettingsViewModel;

abstract class AdvancedPrivacySettingsViewModelBase with Store {
  AdvancedPrivacySettingsViewModelBase(this.type, this._settingsStore)
      : _addCustomNode = false {
    settings = [
                ChoicesListItem<FiatApiMode>(
                  title: S.current.fiat_api,
                  items: FiatApiMode.all,
                  selectedItem: _settingsStore.fiatApiMode,
                  onItemSelected: (FiatApiMode mode) => setFiatMode(mode),
                ),
              
                ChoicesListItem<FiatApiMode>(
                  title: S.current.exchange,
                  items: FiatApiMode.all,
                  selectedItem: _settingsStore.exchangeStatus,
                  onItemSelected: (FiatApiMode mode) => _settingsStore.exchangeStatus = mode,
              ),
      SwitcherListItem(
        title: S.current.add_custom_node,
        value: () => _addCustomNode,
        onValueChange: (_, bool value) => _addCustomNode = value,
      ),
    ];
  }

  late List<SettingsListItem> settings;

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
}
