part of "manage_builtin_networks_cubit.dart";

class ManageBuiltinNetworksState {
  const ManageBuiltinNetworksState({required this.hiddenNetworks});

  final Set<WalletType> hiddenNetworks;

  List<WalletType> get networks => builtinNetworkTypes;

  int get visibleCount => networks.where((type) => !hiddenNetworks.contains(type)).length;

  bool isVisible(WalletType type) => !hiddenNetworks.contains(type);
}

sealed class ManageBuiltinNetworksPresentation {
  const ManageBuiltinNetworksPresentation();
}

final class LastVisibleNetworkHideRefused extends ManageBuiltinNetworksPresentation {
  const LastVisibleNetworkHideRefused();
}
