part of "manage_evm_networks_bloc.dart";

sealed class ManageEvmNetworksPresentation {
  const ManageEvmNetworksPresentation();
}

final class BorrowedTickerConfirmationRequested extends ManageEvmNetworksPresentation {
  const BorrowedTickerConfirmationRequested(this.network);

  final EvmNetwork network;
}

final class RpcChainIdMismatchRefused extends ManageEvmNetworksPresentation {
  const RpcChainIdMismatchRefused({
    required this.networkName,
    required this.answeredChainId,
    required this.expectedChainId,
  });

  final String networkName;
  final int answeredChainId;
  final int expectedChainId;
}

final class RpcNoAnswerRefused extends ManageEvmNetworksPresentation {
  const RpcNoAnswerRefused(this.networkName);

  final String networkName;
}

final class NetworkInUseRefused extends ManageEvmNetworksPresentation {
  const NetworkInUseRefused({required this.networkName, required this.walletCount});

  final String networkName;
  final int walletCount;
}

final class NetworkToggleFailed extends ManageEvmNetworksPresentation {
  const NetworkToggleFailed(this.message);

  final String message;
}
