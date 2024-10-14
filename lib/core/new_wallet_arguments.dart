import 'package:cw_core/wallet_type.dart';

class NewWalletArguments {
  final WalletType type;
  final String? mnemonic;
  final String? parentAddress;
  final bool isChildWallet;

  NewWalletArguments({
    required this.type,
    this.parentAddress,
    this.mnemonic,
    this.isChildWallet = false,
  });
}
