import 'package:cw_core/wallet_type.dart';

class NewWalletArguments {
  final WalletType type;
  final String? mnemonic;
  final bool isChildWallet;

  NewWalletArguments({
    required this.type,
    this.mnemonic,
    this.isChildWallet = false,
  });
}

class WalletGroupArguments {
  WalletGroupArguments({
    required this.types,
    this.currentType,
    this.mnemonic,
  });

  final List<WalletType> types;
  final WalletType? currentType;
  final String? mnemonic;
}

class WalletGroupParams {
  final List<WalletType> restTypes;
  final String sharedMnemonic;
  final bool isChildWallet;
  final String groupKey;
  const WalletGroupParams({
    required this.restTypes,
    required this.sharedMnemonic,
    required this.isChildWallet,
    required this.groupKey,
  });
}