import 'package:cake_wallet/zcash/zcash_network_type.dart';
import 'package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart';
import 'package:cw_core/wallet_type.dart';

class OmniChainCreateGroupRequest {
  OmniChainCreateGroupRequest({
    required this.selectedTypes,
    required this.primaryType,
    required this.groupName,
    this.mnemonic,
    this.passphrase,
    this.walletIcon,
    this.useTestnet = false,
    this.zcashNetwork = ZcashNetworkType.mainnet,
  });

  final Set<WalletType> selectedTypes;
  final WalletType primaryType;
  final String groupName;
  final String? mnemonic;
  final String? passphrase;
  final WalletIcon? walletIcon;
  final bool useTestnet;
  final int zcashNetwork;
}
