import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import 'package:cw_core/wallet_type.dart';

sealed class OmniChainWalletEvent {}

// ---- Step 1: chain selection ----

class OmniChainWalletTypeToggled extends OmniChainWalletEvent {
  OmniChainWalletTypeToggled({required this.type, required this.isSelected});

  final WalletType type;
  final bool isSelected;
}

class OmniChainWalletTypesDeselected extends OmniChainWalletEvent {}

class OmniChainWalletTypesSelected extends OmniChainWalletEvent {}

class OmniChainWalletChainSelectionConfirmed extends OmniChainWalletEvent {}

class OmniChainWalletChainSelectionReopened extends OmniChainWalletEvent {}

// ---- Step 2: customization ----

class OmniChainWalletGroupNameChanged extends OmniChainWalletEvent {
  OmniChainWalletGroupNameChanged(this.groupName);

  final String groupName;
}

class OmniChainWalletGroupNameGenerated extends OmniChainWalletEvent {}

class OmniChainWalletTestnetToggled extends OmniChainWalletEvent {
  OmniChainWalletTestnetToggled(this.value);

  final bool? value;
}

class OmniChainWalletZcashNetworkChanged extends OmniChainWalletEvent {
  OmniChainWalletZcashNetworkChanged(this.network);

  final int network;
}

class OmniChainWalletPassphraseChanged extends OmniChainWalletEvent {
  OmniChainWalletPassphraseChanged(this.passphrase);

  final String? passphrase;
}

class OmniChainWalletCredentialsSubmitted extends OmniChainWalletEvent {}

// ---- Step 3: summary ----

class OmniChainWalletSummaryConfirmed extends OmniChainWalletEvent {}

// ---- Step 4: opening network / creation ----

class OmniChainWalletPrimaryTypeSelected extends OmniChainWalletEvent {
  OmniChainWalletPrimaryTypeSelected(this.type);

  final WalletType type;
}

class OmniChainWalletGroupCreateRequested extends OmniChainWalletEvent {}

class OmniChainWalletIconChanged extends OmniChainWalletEvent {
  OmniChainWalletIconChanged(this.icon);
  final WalletIcon icon;
}
