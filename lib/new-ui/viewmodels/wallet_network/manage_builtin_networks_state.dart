part of "manage_builtin_networks_cubit.dart";

class ManageBuiltinNetworksState {
  const ManageBuiltinNetworksState({required this.networks, required this.hiddenNetworks});

  final List<WalletType> networks;
  final Set<WalletType> hiddenNetworks;

  int get visibleCount => networks.where((type) => !hiddenNetworks.contains(type)).length;

  bool isVisible(WalletType type) => !hiddenNetworks.contains(type);
}

sealed class ManageBuiltinNetworksPresentation {
  const ManageBuiltinNetworksPresentation();
}

final class LastVisibleNetworkHideRefused extends ManageBuiltinNetworksPresentation {
  const LastVisibleNetworkHideRefused();
}
