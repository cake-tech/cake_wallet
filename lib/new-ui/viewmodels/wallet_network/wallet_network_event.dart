part of "wallet_network_bloc.dart";

sealed class WalletNetworkEvent {
  const WalletNetworkEvent();
}

final class WalletNetworkRefreshed extends WalletNetworkEvent {
  const WalletNetworkRefreshed();
}

final class WalletNetworkSearchChanged extends WalletNetworkEvent {
  const WalletNetworkSearchChanged(this.query);

  final String query;
}
