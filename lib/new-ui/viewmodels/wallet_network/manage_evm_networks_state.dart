part of "manage_evm_networks_bloc.dart";

class ManageEvmNetworksState {
  const ManageEvmNetworksState({
    required this.manualNetworks,
    required this.popularNetworks,
    required this.query,
    required this.togglingChainIds,
    required this.alphabeticalNetworks,
    required this.isFetching,
    this.savedCopyDate,
    this.hasFetchFailed = false,
  });

  final List<EvmNetwork> manualNetworks;
  final List<EvmNetwork> popularNetworks;
  final String query;

  final Set<int> togglingChainIds;

  final List<EvmNetwork>? alphabeticalNetworks;

  final bool isFetching;

  final DateTime? savedCopyDate;

  final bool hasFetchFailed;

  ManageEvmNetworksState copyWith({
    List<EvmNetwork>? manualNetworks,
    List<EvmNetwork>? popularNetworks,
    String? query,
    Set<int>? togglingChainIds,
    List<EvmNetwork>? Function()? alphabeticalNetworks,
    bool? isFetching,
    DateTime? Function()? savedCopyDate,
    bool? hasFetchFailed,
  }) =>
      ManageEvmNetworksState(
        manualNetworks: manualNetworks ?? this.manualNetworks,
        popularNetworks: popularNetworks ?? this.popularNetworks,
        query: query ?? this.query,
        togglingChainIds: togglingChainIds ?? this.togglingChainIds,
        alphabeticalNetworks:
            alphabeticalNetworks != null ? alphabeticalNetworks() : this.alphabeticalNetworks,
        isFetching: isFetching ?? this.isFetching,
        savedCopyDate: savedCopyDate != null ? savedCopyDate() : this.savedCopyDate,
        hasFetchFailed: hasFetchFailed ?? this.hasFetchFailed,
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
      matchingSearch(alphabeticalNetworks ?? const []).isEmpty;
}
