part of "network_details_bloc.dart";

enum NetworkField { name, rpcUrl, failoverUrl, chainId, symbol, explorerUrl, iconUrl }

enum NetworkDetailsMode { chainList, manualAdd, manualEdit }

class NetworkDetailsState {
  const NetworkDetailsState({
    required this.mode,
    required this.values,
    this.errors = const {},
    this.walletCount,
    this.contactCount,
    this.isFailoverRevealed = false,
    this.isSaving = false,
  });

  factory NetworkDetailsState.initial(EvmNetwork? network) {
    final NetworkDetailsMode mode;
    if (network == null) {
      mode = NetworkDetailsMode.manualAdd;
    } else if (network.isManual) {
      mode = NetworkDetailsMode.manualEdit;
    } else {
      mode = NetworkDetailsMode.chainList;
    }

    return NetworkDetailsState(
      mode: mode,
      values: {
        NetworkField.name: network?.name ?? "",
        NetworkField.rpcUrl: network?.rpcUrl ?? "",
        NetworkField.failoverUrl: network?.failoverUrl ?? "",
        NetworkField.chainId: network?.chainId.toString() ?? "",
        NetworkField.symbol: network?.symbol ?? "",
        NetworkField.explorerUrl: network?.explorerUrl ?? "",
        NetworkField.iconUrl: network?.iconUrl ?? "",
      },
      isFailoverRevealed: network?.failoverUrl != null,
    );
  }

  final NetworkDetailsMode mode;
  final Map<NetworkField, String> values;
  final Map<NetworkField, String> errors;

  final int? walletCount;
  final int? contactCount;
  final bool isFailoverRevealed;
  final bool isSaving;

  String value(NetworkField field) => values[field] ?? "";

  bool get hasUsageCounts => walletCount != null && contactCount != null;

  bool get hasWallets => (walletCount ?? 0) > 0;

  bool get hasContacts => (contactCount ?? 0) > 0;

  bool get canDelete =>
      mode == NetworkDetailsMode.manualEdit && hasUsageCounts && !hasWallets && !hasContacts;

  bool isReadOnly(NetworkField field) => switch (field) {
        NetworkField.rpcUrl || NetworkField.failoverUrl || NetworkField.symbol => hasWallets,
        NetworkField.chainId => mode == NetworkDetailsMode.chainList || hasWallets || hasContacts,
        NetworkField.name || NetworkField.explorerUrl || NetworkField.iconUrl => false,
      };

  NetworkDetailsState copyWith({
    Map<NetworkField, String>? values,
    Map<NetworkField, String>? errors,
    int? walletCount,
    int? contactCount,
    bool? isFailoverRevealed,
    bool? isSaving,
  }) =>
      NetworkDetailsState(
        mode: mode,
        values: values ?? this.values,
        errors: errors ?? this.errors,
        walletCount: walletCount ?? this.walletCount,
        contactCount: contactCount ?? this.contactCount,
        isFailoverRevealed: isFailoverRevealed ?? this.isFailoverRevealed,
        isSaving: isSaving ?? this.isSaving,
      );
}
