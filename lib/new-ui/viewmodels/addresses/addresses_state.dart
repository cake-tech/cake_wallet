part of "addresses_bloc.dart";

sealed class AddressesState extends Equatable {
  const AddressesState();

  @override
  List<Object?> get props => const [];
}

final class AddressesLoading extends AddressesState {
  const AddressesLoading();
}

final class AddressesLoaded extends AddressesState {
  const AddressesLoaded({
    required this.groups,
    required this.activeAddress,
    required this.searchTerm,
    required this.showHidden,
    required this.hasAccounts,
    required this.currentAccount,
    required this.walletType,
    required this.showAddManualAddresses,
  });

  final List<AddressGroup> groups;
  final String activeAddress;
  final String searchTerm;
  final bool showHidden;
  final bool hasAccounts;
  final AddressAccount? currentAccount;
  final WalletType walletType;
  final bool showAddManualAddresses;

  List<AddressGroup> get displayableGroups {
    final term = searchTerm.toLowerCase();
    return groups
        .map((g) {
          final entries = g.entries.where((e) {
            if (e.isHidden != showHidden) {
              return false;
            }
            if (term.isEmpty) {
              return true;
            }
            final matchesAddress = e.address.toLowerCase().contains(term);
            final matchesLabel = e.label?.toLowerCase().contains(term) ?? false;
            return matchesAddress || matchesLabel;
          }).toList();
          return AddressGroup(header: g.header, entries: entries);
        })
        .where((g) => g.entries.isNotEmpty)
        .toList();
  }

  AddressesLoaded copyWith({
    List<AddressGroup>? groups,
    String? activeAddress,
    String? searchTerm,
    bool? showHidden,
    bool? hasAccounts,
    AddressAccount? currentAccount,
    bool clearAccount = false,
    WalletType? walletType,
    bool? showAddManualAddresses,
  }) => AddressesLoaded(
      groups: groups ?? this.groups,
      activeAddress: activeAddress ?? this.activeAddress,
      searchTerm: searchTerm ?? this.searchTerm,
      showHidden: showHidden ?? this.showHidden,
      hasAccounts: hasAccounts ?? this.hasAccounts,
      currentAccount: clearAccount ? null : (currentAccount ?? this.currentAccount),
      walletType: walletType ?? this.walletType,
      showAddManualAddresses: showAddManualAddresses ?? this.showAddManualAddresses,
    );

  @override
  List<Object?> get props => [
        groups.length,
        activeAddress,
        searchTerm,
        showHidden,
        hasAccounts,
        currentAccount,
        walletType,
        showAddManualAddresses,
      ];
}

final class AddressesFailure extends AddressesState {
  const AddressesFailure(this.code);

  final AddressesFailureCode code;

  @override
  List<Object?> get props => [code];
}

enum AddressesFailureCode {
  addressListUnavailable,
  saveFailed,
}
