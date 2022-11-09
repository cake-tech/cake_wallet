import 'package:cake_wallet/view_model/settings/switcher_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'privacy_settings_view_model.g.dart';

class PrivacySettingsViewModel = PrivacySettingsViewModelBase
    with _$PrivacySettingsViewModel;

abstract class PrivacySettingsViewModelBase with Store {
  PrivacySettingsViewModelBase(this.type)
      : _disableFiat = false,
        _disableExchange = false,
        _addCustomNode = false {
    settings = [
      SwitcherListItem(
        // TODO: replace when Disable Fiat PR is merged
        title: "Disable Fiat API",
        // title: S.current.disable_fiat,
        value: () => _disableFiat,
        onValueChange: (_, bool value) => _disableFiat = value,
      ),
      SwitcherListItem(
        title: "Disable Exchange",
        // title: S.current.disable_exchange,
        value: () => _disableExchange,
        onValueChange: (_, bool value) => _disableExchange = value,
      ),
      SwitcherListItem(
        title: "Add New Custom Node",
        // title: S.current.add_custom_node,
        value: () => _addCustomNode,
        onValueChange: (_, bool value) => _addCustomNode = value,
      ),
    ];
  }

  late List<SwitcherListItem> settings;

  @observable
  bool _disableFiat = false;

  @observable
  bool _disableExchange = false;

  @observable
  bool _addCustomNode = false;

  final WalletType type;

  @computed
  bool get addCustomNode => _addCustomNode;
}
