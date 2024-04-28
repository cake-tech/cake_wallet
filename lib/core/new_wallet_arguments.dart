import 'package:cw_core/wallet_type.dart';

class NewWalletArguments {
  final WalletType type;
  final String? mnemonic;
  final String? parentAddress;

  NewWalletArguments({
    required this.type,
    this.parentAddress,
    this.mnemonic,
  });
}
