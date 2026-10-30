import "package:cake_wallet/entities/wallet_group.dart";

const Object _noChange = Object();

enum WalletEditError { nameEmpty, nameTaken, renameFailed, iconFailed, deleteFailed }

class WalletEditState {
  WalletEditState({
    this.groupKey = "",
    this.group,
    this.name = "",
    this.error,
    this.closeRequested = false,
  });

  final String groupKey;


  final WalletGroup? group;

  final String name;

  final WalletEditError? error;

  final bool closeRequested;

  bool get canSubmitRename =>
      name.trim().isNotEmpty && name.trim() != (group?.groupName ?? "").trim();

  WalletEditState copyWith({
    String? groupKey,
    Object? group = _noChange,
    String? name,
    bool? isDeleting,
    Object? error = _noChange,
    bool? closeRequested,
  }) =>
      WalletEditState(
        groupKey: groupKey ?? this.groupKey,
        group: group == _noChange ? this.group : group as WalletGroup?,
        name: name ?? this.name,
        error: error == _noChange ? this.error : error as WalletEditError?,
        closeRequested: closeRequested ?? this.closeRequested,
      );
}