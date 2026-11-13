import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/entities/wallet_contact_group.dart";
import "package:flutter/foundation.dart";

const Object _noChange = Object();

enum WalletContactsStatus { initial, loading, loaded, failure }

class WalletContactsState {
  const WalletContactsState({
    this.status = WalletContactsStatus.initial,
    this.groups = const [],
    this.currentGroupId,
    this.error,
  });

  final WalletContactsStatus status;

  /// Current group first, then the others in the group service's order.
  final List<WalletContactGroup> groups;
  final String? currentGroupId;
  final Object? error;

  WalletContactGroup? get currentGroup {
    for (final group in groups) {
      if (group.isCurrent) return group;
    }
    return null;
  }

  /// Every group except the current one (what "Other Wallets" will list).
  List<WalletContactGroup> get otherGroups => groups.where((g) => !g.isCurrent).toList();

  /// All contacts of all groups, already filtered by the cubit's currency (picker list).
  List<WalletContact> get allContacts => groups.expand((g) => g.contacts).toList();

  WalletContactsState copyWith({
    WalletContactsStatus? status,
    List<WalletContactGroup>? groups,
    Object? currentGroupId = _noChange,
    Object? error = _noChange,
  }) =>
      WalletContactsState(
        status: status ?? this.status,
        groups: groups ?? this.groups,
        currentGroupId:
            currentGroupId == _noChange ? this.currentGroupId : currentGroupId as String?,
        error: error == _noChange ? this.error : error,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletContactsState &&
          other.status == status &&
          other.currentGroupId == currentGroupId &&
          other.error == error &&
          listEquals(other.groups, groups);

  @override
  int get hashCode => Object.hash(status, currentGroupId, error, Object.hashAll(groups));
}
