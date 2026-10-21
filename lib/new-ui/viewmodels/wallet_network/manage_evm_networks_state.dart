part of "manage_evm_networks_bloc.dart";

sealed class ChainListStatus {
  const ChainListStatus();
}

class ChainListFetching extends ChainListStatus {
  const ChainListFetching();
}

class ChainListLoaded extends ChainListStatus {
  const ChainListLoaded();
}

class ChainListSavedCopy extends ChainListStatus {
  const ChainListSavedCopy(this.date);

  final DateTime date;
}

class ChainListFetchFailed extends ChainListStatus {
  const ChainListFetchFailed();
}

class ManageEvmNetworksState {
  const ManageEvmNetworksState({
    required this.manualNetworks,
    required this.popularNetworks,
    required this.alphabeticalNetworks,
    required this.chainListStatus,
    required this.query,
    required this.togglingChainIds,
  });

  final List<EvmNetwork> manualNetworks;
  final List<EvmNetwork> popularNetworks;
  final List<EvmNetwork> alphabeticalNetworks;
  final ChainListStatus chainListStatus;
  final String query;

  final Set<int> togglingChainIds;

  ManageEvmNetworksState copyWith({
    List<EvmNetwork>? manualNetworks,
    List<EvmNetwork>? popularNetworks,
    List<EvmNetwork>? alphabeticalNetworks,
    ChainListStatus? chainListStatus,
    String? query,
    Set<int>? togglingChainIds,
  }) =>
      ManageEvmNetworksState(
        manualNetworks: manualNetworks ?? this.manualNetworks,
        popularNetworks: popularNetworks ?? this.popularNetworks,
        alphabeticalNetworks: alphabeticalNetworks ?? this.alphabeticalNetworks,
        chainListStatus: chainListStatus ?? this.chainListStatus,
        query: query ?? this.query,
        togglingChainIds: togglingChainIds ?? this.togglingChainIds,
      );

  List<EvmNetwork> matchingSearch(List<EvmNetwork> networks) {
    final lowered = query.trim().toLowerCase();
    if (lowered.isEmpty) {
      return networks;
    }

    return networks
        .where(
          (network) =>
              network.name.toLowerCase().contains(lowered) ||
              network.symbol.toLowerCase().contains(lowered) ||
              network.chainId.toString() == lowered,
        )
        .toList();
  }

  bool get hasNoMatch =>
      query.trim().isNotEmpty &&
      matchingSearch(manualNetworks).isEmpty &&
      matchingSearch(popularNetworks).isEmpty &&
      matchingSearch(alphabeticalNetworks).isEmpty;
}
