import "package:bloc/bloc.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/wallet_type.dart";

part "manage_builtin_networks_state.dart";

class ManageBuiltinNetworksCubit extends Cubit<ManageBuiltinNetworksState>
    with BlocPresentationMixin<ManageBuiltinNetworksState, ManageBuiltinNetworksPresentation> {
  ManageBuiltinNetworksCubit(this._settingsStore)
      : super(
          ManageBuiltinNetworksState(hiddenNetworks: {..._settingsStore.hiddenBuiltinNetworks}),
        );

  final SettingsStore _settingsStore;

  void toggleVisibility(WalletType type) {
    final hidden = {...state.hiddenNetworks};

    if (!hidden.remove(type)) {
      if (state.visibleCount == 1) {
        emitPresentation(const LastVisibleNetworkHideRefused());
        return;
      }

      hidden.add(type);
    }

    _settingsStore.setHiddenBuiltinNetworks(hidden);
    emit(ManageBuiltinNetworksState(hiddenNetworks: hidden));
  }
}
