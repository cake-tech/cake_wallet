import 'package:cw_core/wallet_type.dart';

class OmniChainWalletState {
  OmniChainWalletState({
    Set<WalletType>? selectedTypes,
    Set<WalletType>? allWalletTypes,
    this.name = '',
  })  : selectedTypes = selectedTypes ?? <WalletType>{},
        allWalletTypes = allWalletTypes ?? <WalletType>{};

  final Set<WalletType> selectedTypes;
  final Set<WalletType> allWalletTypes;
  final String name;

  bool get hasAnySelected => selectedTypes.isNotEmpty;

  bool isSelected(WalletType type) => selectedTypes.contains(type);

  OmniChainWalletState copyWith({
    Set<WalletType>? selectedTypes,
    Set<WalletType>? allWalletTypes,
    String? name,
  }) {
    return OmniChainWalletState(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      allWalletTypes: allWalletTypes ?? this.allWalletTypes,
      name: name ?? this.name,
    );
  }
}
