import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/zcash/zcash_network_type.dart";
import "package:cw_core/wallet_type.dart";

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
    this.walletIcon,
    this.groupNameError,
    this.providedPassphrase,
    this.useTestnet = false,
    this.zcashNetwork = ZcashNetworkType.mainnet,
  });

  final Set<WalletType> selectedTypes;
  final String groupName;
  final WalletIcon? walletIcon;
  final String? groupNameError;
  final String? providedPassphrase;
  final bool useTestnet;
  final int zcashNetwork;

  bool get canContinue => groupName.trim().isNotEmpty && groupNameError == null;

  WalletCreationCustomization copyWith({
    String? groupName,
    Object? walletIcon = _noChange,
    Object? groupNameError = _noChange,
    Object? providedPassphrase = _noChange,
    bool? useTestnet,
    int? zcashNetwork,
  }) => WalletCreationCustomization(
    selectedTypes: selectedTypes,
    groupName: groupName ?? this.groupName,
    walletIcon: walletIcon == _noChange ? this.walletIcon : walletIcon as WalletIcon?,
    groupNameError:
    groupNameError == _noChange ? this.groupNameError : groupNameError as String?,
    providedPassphrase:
    providedPassphrase == _noChange ? this.providedPassphrase : providedPassphrase as String?,
    useTestnet: useTestnet ?? this.useTestnet,
    zcashNetwork: zcashNetwork ?? this.zcashNetwork,
  );
}

/// Step 3 — read-only recap of the collected input before creation.
class WalletCreationSummary extends WalletCreationState {
  const WalletCreationSummary({
    required this.selectedTypes,
    required this.groupName,
    this.walletIcon,
    this.providedPassphrase,
    this.useTestnet = false,
    this.zcashNetwork = ZcashNetworkType.mainnet,
  });

  final Set<WalletType> selectedTypes;
  final String groupName;
  final WalletIcon? walletIcon;
  final String? providedPassphrase;
  final bool useTestnet;
  final int zcashNetwork;
}

/// Step 4 — the user picks the initial network to open.
class WalletCreationOpeningNetwork extends WalletCreationState {
  const WalletCreationOpeningNetwork({
    required this.selectedTypes,
    required this.groupName,
    this.walletIcon,
    this.primaryType,
    this.creationError,
    this.providedPassphrase,
    this.useTestnet = false,
    this.zcashNetwork = ZcashNetworkType.mainnet,
  });

  final Set<WalletType> selectedTypes;
  final String groupName;
  final WalletIcon? walletIcon;
  final WalletType? primaryType;
  final String? creationError;
  final String? providedPassphrase;
  final bool useTestnet;
  final int zcashNetwork;

  bool get canCreate => primaryType != null;

  WalletCreationOpeningNetwork copyWith({
    Object? primaryType = _noChange,
    Object? creationError = _noChange,
  }) => WalletCreationOpeningNetwork(
    selectedTypes: selectedTypes,
    groupName: groupName,
    walletIcon: walletIcon,
    primaryType: primaryType == _noChange ? this.primaryType : primaryType as WalletType?,
    creationError: creationError == _noChange ? this.creationError : creationError as String?,
    providedPassphrase: providedPassphrase,
    useTestnet: useTestnet,
    zcashNetwork: zcashNetwork,
  );
}

/// Step 5 — the group is being created; the UI shows a loading indicator.

class WalletCreationCreating extends WalletCreationState {
  const WalletCreationCreating({required this.request});

  final WalletCreationOpeningNetwork request;
}

/// Step 6 — the group exists and its primary is the current wallet, but the
/// dashboard is still gated behind seed backup + verification.
class WalletCreationSeedBackup extends WalletCreationState {
  const WalletCreationSeedBackup({
    required this.groupName,
    required this.selectedTypes,
    required this.primaryType,
    this.walletIcon,
  });

  final String groupName;
  final Set<WalletType> selectedTypes;
  final WalletType primaryType;
  final WalletIcon? walletIcon;
}

/// Terminal step — the group exists; the app navigates to the dashboard.
class WalletCreated extends WalletCreationState {
  const WalletCreated({required this.groupName});

  final String groupName;
}