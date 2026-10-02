part of "wallet_network_bloc.dart";

class WalletNetworkRow {
  const WalletNetworkRow({
    required this.network,
    required this.name,
    required this.symbol,
    this.iconPath,
  });

  final WalletNetwork network;
  final String name;
  final String symbol;
  final String? iconPath;

  bool matches(String query) {
    final lowered = query.trim().toLowerCase();
    return lowered.isEmpty ||
        name.toLowerCase().contains(lowered) ||
        symbol.toLowerCase().contains(lowered);
  }
}

class WalletNetworkState {
  const WalletNetworkState({
    required this.query,
    required this.builtinRows,
    required this.addedRows,
    required this.hasAddedNetworks,
  });

  final String query;
  final List<WalletNetworkRow> builtinRows;
  final List<WalletNetworkRow> addedRows;
  final bool hasAddedNetworks;

  WalletNetworkState copyWith({String? query}) => WalletNetworkState(
        query: query ?? this.query,
        builtinRows: builtinRows,
        addedRows: addedRows,
        hasAddedNetworks: hasAddedNetworks,
      );

  List<WalletNetworkRow> get visibleBuiltinRows =>
      builtinRows.where((row) => row.matches(query)).toList();

  List<WalletNetworkRow> get visibleAddedRows =>
      addedRows.where((row) => row.matches(query)).toList();
}
