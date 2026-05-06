import 'package:cw_core/wallet_type.dart';

sealed class OmniChainWalletEvent {}

class OmniChainWalletGroupNameChanged extends OmniChainWalletEvent {
  OmniChainWalletGroupNameChanged(this.groupName);
  final String groupName;
}

class OmniChainWalletGroupNameGenerated extends OmniChainWalletEvent {}

class OmniChainWalletTypeToggled extends OmniChainWalletEvent {
  OmniChainWalletTypeToggled({required this.type, required this.isSelected});

  final WalletType type;
  final bool isSelected;
}

class OmniChainWalletPrimaryTypeSelected extends OmniChainWalletEvent {
  OmniChainWalletPrimaryTypeSelected(this.type);

  final WalletType type;
}

class OmniChainWalletTypesDeselected extends OmniChainWalletEvent {}

class OmniChainWalletTypesSelected extends OmniChainWalletEvent {}

class OmniChainWalletGroupCreateRequested extends OmniChainWalletEvent {}
