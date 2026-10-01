import "dart:io";

import "package:bloc/bloc.dart";
import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/hardware/device_connection_type.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

part "wallet_network_event.dart";
part "wallet_network_state.dart";

sealed class WalletNetworkMode {
  const WalletNetworkMode();
}

final class WalletNetworkCreate extends WalletNetworkMode {
  const WalletNetworkCreate();
}

final class WalletNetworkRestore extends WalletNetworkMode {
  const WalletNetworkRestore();
}

final class WalletNetworkRestoreFromQr extends WalletNetworkMode {
  const WalletNetworkRestoreFromQr();
}

final class WalletNetworkHardware extends WalletNetworkMode {
  const WalletNetworkHardware(this.hardwareWalletType);

  final HardwareWalletType hardwareWalletType;
}

class WalletNetworkBloc extends Bloc<WalletNetworkEvent, WalletNetworkState> {
  WalletNetworkBloc(this.mode, this._settingsStore)
      : super(_buildState(mode, _settingsStore, query: "")) {
    on<WalletNetworkRefreshed>(_onRefreshed);
    on<WalletNetworkSearchChanged>(_onSearchChanged);
  }

  final WalletNetworkMode mode;
  final SettingsStore _settingsStore;

  void _onRefreshed(WalletNetworkRefreshed event, Emitter<WalletNetworkState> emit) =>
      emit(_buildState(mode, _settingsStore, query: state.query));

  void _onSearchChanged(WalletNetworkSearchChanged event, Emitter<WalletNetworkState> emit) =>
      emit(state.copyWith(query: event.query));

  static WalletNetworkState _buildState(
    WalletNetworkMode mode,
    SettingsStore settingsStore, {
    required String query,
  }) {
    final hardwareType = mode is WalletNetworkHardware ? mode.hardwareWalletType : null;

    bool isSupportedByHardwareWallet(WalletType type) =>
        hardwareType == null ||
        DeviceConnectionType.supportedConnectionTypes(type, hardwareType, Platform.isIOS)
            .isNotEmpty;

    final builtinRows = builtinNetworkTypes
        .where((type) => !settingsStore.hiddenBuiltinNetworks.contains(type))
        .where(isSupportedByHardwareWallet)
        .map(
          (type) => WalletNetworkRow(
            network: WalletNetwork.builtin(type),
            name: walletTypeToDisplayName(type),
            symbol: walletTypeToCryptoCurrency(type).title,
            iconPath: builtinNetworkIconPath(type),
          ),
        )
        .toList();

    final addedNetworks = settingsStore.evmNetworks.values
        .where((chain) => chain.source != ChainSource.builtin)
        .toList();

    final addedRows = isSupportedByHardwareWallet(WalletType.evm)
        ? addedNetworks
            .map(
              (chain) => WalletNetworkRow(
                network: WalletNetwork.added(chain.chainId),
                name: chain.name,
                symbol: chain.currency.title,
                iconPath: chain.iconPath,
                isManual: chain.source == ChainSource.manual,
              ),
            )
            .toList()
        : const <WalletNetworkRow>[];

    return WalletNetworkState(
      query: query,
      builtinRows: builtinRows,
      addedRows: addedRows,
      hasAddedNetworks: addedNetworks.isNotEmpty,
    );
  }
}
