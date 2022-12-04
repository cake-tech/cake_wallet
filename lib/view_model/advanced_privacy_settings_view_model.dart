import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/settings/switcher_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'advanced_privacy_settings_view_model.g.dart';

class AdvancedPrivacySettingsViewModel = AdvancedPrivacySettingsViewModelBase
    with _$AdvancedPrivacySettingsViewModel;

abstract class AdvancedPrivacySettingsViewModelBase with Store {
  AdvancedPrivacySettingsViewModelBase(this.type, this._settingsStore)
      : _disableFiat = false,
        _addCustomNode = false {
    settings = [
      // TODO: uncomment when Disable Fiat PR is merged
      // SwitcherListItem(
      //   title: S.current.disable_fiat,
      //   value: () => _disableFiat,
      //   onValueChange: (_, bool value) => _disableFiat = value,
      // ),
      SwitcherListItem(
        title: S.current.disable_exchange,
        value: () => _settingsStore.disableExchange,
        onValueChange: (_, bool value) {
          _settingsStore.disableExchange = value;
        },
      ),
      SwitcherListItem(
        title: S.current.add_custom_node,
        value: () => _addCustomNode,
        onValueChange: (_, bool value) => _addCustomNode = value,
      ),
    ];
  }

  late List<SwitcherListItem> settings;

  @observable
  bool _disableFiat = false;

  @observable
  bool _addCustomNode = false;

  final WalletType type;
  final SettingsStore _settingsStore;

  @computed
  bool get addCustomNode => _addCustomNode;
}
