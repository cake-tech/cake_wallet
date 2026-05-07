import 'package:cw_core/wallet_type.dart';

const Object _noChange = Object();

class OmniChainWalletState {
  OmniChainWalletState({
    Set<WalletType>? selectedTypes,
    Set<WalletType>? allWalletTypes,
    String? groupName,
    this.groupNameError,
    this.primaryType,
    this.providedMnemonic,
    this.providedPassphrase,
    this.groupCreated = false,
  })  : selectedTypes = selectedTypes ?? <WalletType>{},
        allWalletTypes = allWalletTypes ?? <WalletType>{},
        _groupName = groupName;

  final Set<WalletType> selectedTypes;
  final Set<WalletType> allWalletTypes;
  final String? providedMnemonic;
  final String? providedPassphrase;
  final bool groupCreated;
  final String? _groupName;
  final String? groupNameError;
  final WalletType? primaryType;

  String get groupName => _groupName ?? '';

  bool get hasAnySelected => selectedTypes.isNotEmpty;

  bool get canContinue => hasAnySelected && groupName.trim().isNotEmpty && groupNameError == null;

  bool isSelected(WalletType type) => selectedTypes.contains(type);

  OmniChainWalletState copyWith({
    Set<WalletType>? selectedTypes,
    Set<WalletType>? allWalletTypes,
    String? groupName,
    Object? groupNameError = _noChange,
    Object? primaryType = _noChange,
    bool? groupCreated,
  }) {
    return OmniChainWalletState(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      allWalletTypes: allWalletTypes ?? this.allWalletTypes,
      groupName: groupName ?? this.groupName,
      groupNameError: groupNameError == _noChange ? this.groupNameError : groupNameError as String?,
      primaryType: primaryType == _noChange ? this.primaryType : primaryType as WalletType?,
      groupCreated: groupCreated ?? this.groupCreated,
    );
  }
}
