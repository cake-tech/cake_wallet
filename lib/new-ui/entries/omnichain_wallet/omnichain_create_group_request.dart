import 'package:cw_core/wallet_type.dart';

class OmniChainCreateGroupRequest {
  OmniChainCreateGroupRequest({
    required this.selectedTypes,
    required this.primaryType,
    required this.groupName,
    this.mnemonic,
    this.passphrase,
  });

  final Set<WalletType> selectedTypes;
  final WalletType primaryType;
  final String groupName;
  final String? mnemonic;
  final String? passphrase;
}
