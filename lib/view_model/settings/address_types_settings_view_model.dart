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

  /// Enables or disables an optional address type.
  ///
  /// Returns `false` when the type can't be disabled because it still has funds.
  @action
  Future<bool> setAddressTypeEnabled(ReceivePageOption option, bool enabled) async {
    if (enabled) {
      enabledOptionalAddressTypes.add(option);
      await bitcoin!.setAddressTypeEnabled(_wallet, option, true);
      return true;
    }

    final changed = await bitcoin!.setAddressTypeEnabled(_wallet, option, false);
    if (!changed) {
      return false;
    }

    enabledOptionalAddressTypes.remove(option);
    return true;
  }
}
