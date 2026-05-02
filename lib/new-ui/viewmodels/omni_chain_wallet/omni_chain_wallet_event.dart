import 'package:cw_core/wallet_type.dart';

sealed class OmniChainWalletEvent {}

class OmniChainWalletNameChanged extends OmniChainWalletEvent {
  OmniChainWalletNameChanged(this.name);
  final String name;
}

class OmniChainWalletNameGenerated extends OmniChainWalletEvent {}

class OmniChainWalletTypeToggled extends OmniChainWalletEvent {
  OmniChainWalletTypeToggled({required this.type, required this.isSelected});

  final WalletType type;
  final bool isSelected;
}

class OmniChainWalletTypesDeselected extends OmniChainWalletEvent {}

class OmniChainWalletTypesSelected extends OmniChainWalletEvent {}
