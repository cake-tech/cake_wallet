import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_base.dart";
import "package:mobx/mobx.dart";

part "address_types_settings_view_model.g.dart";

class AddressTypesSettingsViewModel = AddressTypesSettingsViewModelBase
    with _$AddressTypesSettingsViewModel;

abstract class AddressTypesSettingsViewModelBase with Store {
  AddressTypesSettingsViewModelBase(this._wallet)
      : optionalAddressTypes = bitcoin!.getOptionalAddressTypeOptions(_wallet),
        enabledOptionalAddressTypes = ObservableSet() {
    enabledOptionalAddressTypes.addAll(
        optionalAddressTypes.where((option) => bitcoin!.isAddressTypeEnabled(_wallet, option)));
  }

  final WalletBase _wallet;

  /// The Bitcoin address types that stay off, never derived nor synced, until enabled here.
  final List<ReceivePageOption> optionalAddressTypes;

  final ObservableSet<ReceivePageOption> enabledOptionalAddressTypes;

  @action
  Future<void> setAddressTypeEnabled(ReceivePageOption option, bool enabled) async {
    if (enabled) {
      enabledOptionalAddressTypes.add(option);
    } else {
      enabledOptionalAddressTypes.remove(option);
    }

    await bitcoin!.setAddressTypeEnabled(_wallet, option, enabled);
  }
}
