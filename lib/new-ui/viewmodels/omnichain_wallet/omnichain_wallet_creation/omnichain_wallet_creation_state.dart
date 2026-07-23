import 'package:cw_core/wallet_type.dart';

const Object _noChange = Object();

/// States of the omnichain wallet creation flow, one class per step:
///
/// [WalletCreationChainSelection] -> [WalletCreationCustomization] -> [WalletCreationSummary]
/// -> [WalletCreationOpeningNetwork] -> [WalletCreationCreating] -> [WalletCreated]
///

sealed class WalletCreationState {
  const WalletCreationState();
}

/// Step 1 — the user picks which networks the wallet group will enable.
class WalletCreationChainSelection extends WalletCreationState {
  WalletCreationChainSelection({
    required this.allWalletTypes,
    Set<WalletType>? selectedTypes,
  }) : selectedTypes = selectedTypes ?? <WalletType>{};

  final Set<WalletType> allWalletTypes;
  final Set<WalletType> selectedTypes;

  bool get hasAnySelected => selectedTypes.isNotEmpty;

  bool isSelected(WalletType type) => selectedTypes.contains(type);

  WalletCreationChainSelection copyWith({Set<WalletType>? selectedTypes}) => WalletCreationChainSelection(
    allWalletTypes: allWalletTypes,
    selectedTypes: selectedTypes ?? this.selectedTypes,
  );
}

/// Step 2 — the user names the wallet group.
class WalletCreationCustomization extends WalletCreationState {
  const WalletCreationCustomization({
    required this.selectedTypes,
    this.groupName = "",
    this.groupNameError,
    this.providedPassphrase,
  });

  final Set<WalletType> selectedTypes;
  final String groupName;
  final String? groupNameError;
  final String? providedPassphrase;

  bool get canContinue => groupName.trim().isNotEmpty && groupNameError == null;

  WalletCreationCustomization copyWith({
    String? groupName,
    Object? groupNameError = _noChange,
    Object? providedMnemonic = _noChange,
    Object? providedPassphrase = _noChange,
  }) => WalletCreationCustomization(
    selectedTypes: selectedTypes,
    groupName: groupName ?? this.groupName,
    groupNameError: groupNameError == _noChange ? this.groupNameError : groupNameError as String?,
    providedPassphrase:
    providedPassphrase == _noChange ? this.providedPassphrase : providedPassphrase as String?,
  );
}

/// Step 3 — read-only recap of the collected input before creation.
class WalletCreationSummary extends WalletCreationState {
  const WalletCreationSummary({
    required this.selectedTypes,
    required this.groupName,
    this.providedPassphrase,
  });

  final Set<WalletType> selectedTypes;
  final String groupName;
  final String? providedPassphrase;
}

/// Step 4 — the user picks the initial network to open.
class WalletCreationOpeningNetwork extends WalletCreationState {
  const WalletCreationOpeningNetwork({
    required this.selectedTypes,
    required this.groupName,
    this.primaryType,
    this.creationError,
    this.providedPassphrase,
  });

  final Set<WalletType> selectedTypes;
  final String groupName;
  final WalletType? primaryType;
  final String? creationError;
  final String? providedPassphrase;

  bool get canCreate => primaryType != null;

  WalletCreationOpeningNetwork copyWith({
    Object? primaryType = _noChange,
    Object? creationError = _noChange,
  }) => WalletCreationOpeningNetwork(
      selectedTypes: selectedTypes,
      groupName: groupName,
      primaryType: primaryType == _noChange ? this.primaryType : primaryType as WalletType?,
      creationError: creationError == _noChange ? this.creationError : creationError as String?,
      providedPassphrase: providedPassphrase,
    );
}

/// Step 5 — the group is being created; the UI shows a loading indicator.

class WalletCreationCreating extends WalletCreationState {
  const WalletCreationCreating({required this.request});

  final WalletCreationOpeningNetwork request;
}

/// Terminal step — the group exists; the app navigates to the dashboard.
class WalletCreated extends WalletCreationState {
  const WalletCreated({required this.groupName});

  final String groupName;
}