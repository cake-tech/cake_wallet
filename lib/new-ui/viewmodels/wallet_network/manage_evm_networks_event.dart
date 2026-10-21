part of "manage_evm_networks_bloc.dart";

sealed class ManageEvmNetworksEvent {
  const ManageEvmNetworksEvent();
}

final class _Init extends ManageEvmNetworksEvent {
  const _Init();
}

final class ChainListRetryRequested extends ManageEvmNetworksEvent {
  const ChainListRetryRequested();
}

final class ManageEvmNetworksSearchChanged extends ManageEvmNetworksEvent {
  const ManageEvmNetworksSearchChanged(this.query);

  final String query;
}

final class NetworkToggleRequested extends ManageEvmNetworksEvent {
  const NetworkToggleRequested(this.network, {required this.shouldEnable});

  final EvmNetwork network;
  final bool shouldEnable;
}

final class BorrowedTickerConfirmationAnswered extends ManageEvmNetworksEvent {
  const BorrowedTickerConfirmationAnswered(this.network, {required this.isConfirmed});

  final EvmNetwork network;
  final bool isConfirmed;
}

final class _NetworkToggled extends ManageEvmNetworksEvent {
  const _NetworkToggled(this.network, {required this.shouldEnable});

  final EvmNetwork network;
  final bool shouldEnable;
}

final class NetworksChanged extends ManageEvmNetworksEvent {
  const NetworksChanged();
}
