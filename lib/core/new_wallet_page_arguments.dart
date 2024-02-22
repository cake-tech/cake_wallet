import 'package:cw_core/wallet_type.dart';

class NewWalletPageArguments {
  final WalletType type;
  final String? mnemonic;

  NewWalletPageArguments({
    required this.type,
    this.mnemonic,
  });
}
