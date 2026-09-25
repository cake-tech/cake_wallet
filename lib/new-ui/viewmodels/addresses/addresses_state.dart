part of "addresses_bloc.dart";

sealed class AddressesState {
  const AddressesState();
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
    required this.walletId,
    required this.walletType,
    required this.walletName,
    required this.showAddManualAddresses,
    required this.canSetLabel,
    required this.canHide,
    this.isSaving = false,
  });

  final List<AddressGroup> groups;
  final String activeAddress;
  final String searchTerm;
  final bool showHidden;
  final bool hasAccounts;
  final String walletId;
  final WalletType walletType;
  final String walletName;
  final bool showAddManualAddresses;
  final bool canSetLabel;
  final bool canHide;
  final bool isSaving;

  bool get hasHiddenAddresses => groups.any((g) => g.entries.any((e) => e.isHidden));

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
    bool? isSaving,
  }) =>
      AddressesLoaded(
        groups: groups ?? this.groups,
        activeAddress: activeAddress ?? this.activeAddress,
        searchTerm: searchTerm ?? this.searchTerm,
        showHidden: showHidden,
        hasAccounts: hasAccounts,
        walletId: walletId,
        walletType: walletType,
        walletName: walletName,
        showAddManualAddresses: showAddManualAddresses,
        canSetLabel: canSetLabel,
        canHide: canHide,
        isSaving: isSaving ?? this.isSaving,
      );
}

final class AddressesFailure extends AddressesState {
  const AddressesFailure();

  String get message => S.current.receive_error_address_list;
}
