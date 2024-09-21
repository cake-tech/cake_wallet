import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletTypeArguments {
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final bool isCreate;
  final bool isHardwareWallet;

  NewWalletTypeArguments({
    required this.onTypeSelected,
    required this.isCreate,
    required this.isHardwareWallet,
  });
}
