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
    required this.walletId,
    required this.walletType,
    required this.walletName,
    required this.accountLabel,
    required this.hasHiddenAddresses,
    required this.showAddManualAddresses,
    required this.hasBalance,
    required this.hasReceived,
    required this.canSetLabel,
    required this.isSilentPayments,
    this.isSaving = false,
    this.failureCode,
  });

  final List<AddressGroup> groups;
  final String activeAddress;
  final String searchTerm;
  final bool showHidden;
  final bool hasAccounts;
  final String walletId;
  final WalletType walletType;
  final String walletName;
  final String accountLabel;
  final bool hasHiddenAddresses;
  final bool showAddManualAddresses;
  final bool hasBalance;
  final bool hasReceived;
  final bool canSetLabel;
  final bool isSilentPayments;
  final bool isSaving;
  final AddressesFailureCode? failureCode;

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
    String? walletId,
    WalletType? walletType,
    String? walletName,
    String? accountLabel,
    bool? hasHiddenAddresses,
    bool? showAddManualAddresses,
    bool? hasBalance,
    bool? hasReceived,
    bool? canSetLabel,
    bool? isSilentPayments,
    bool? isSaving,
    AddressesFailureCode? failureCode,
    bool clearFailureCode = false,
  }) =>
      AddressesLoaded(
        groups: groups ?? this.groups,
        activeAddress: activeAddress ?? this.activeAddress,
        searchTerm: searchTerm ?? this.searchTerm,
        showHidden: showHidden ?? this.showHidden,
        hasAccounts: hasAccounts ?? this.hasAccounts,
        walletId: walletId ?? this.walletId,
        walletType: walletType ?? this.walletType,
        walletName: walletName ?? this.walletName,
        accountLabel: accountLabel ?? this.accountLabel,
        hasHiddenAddresses: hasHiddenAddresses ?? this.hasHiddenAddresses,
        showAddManualAddresses: showAddManualAddresses ?? this.showAddManualAddresses,
        hasBalance: hasBalance ?? this.hasBalance,
        hasReceived: hasReceived ?? this.hasReceived,
        canSetLabel: canSetLabel ?? this.canSetLabel,
        isSilentPayments: isSilentPayments ?? this.isSilentPayments,
        isSaving: isSaving ?? this.isSaving,
        failureCode: clearFailureCode ? null : (failureCode ?? this.failureCode),
      );

  @override
  List<Object?> get props => [
        groups,
        activeAddress,
        searchTerm,
        showHidden,
        hasAccounts,
        walletId,
        walletType,
        walletName,
        accountLabel,
        hasHiddenAddresses,
        showAddManualAddresses,
        hasBalance,
        hasReceived,
        canSetLabel,
        isSilentPayments,
        isSaving,
        failureCode,
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
