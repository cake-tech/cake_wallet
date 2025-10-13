import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletTypeArguments {
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final bool isCreate;
  final bool isHardwareWallet;
  final bool allowMultiSelect;
  final bool constrainBip39Only;
  final Set<WalletType>? preselectedTypes;
  final Object? credentials;

  NewWalletTypeArguments({
    required this.onTypeSelected,
    required this.isCreate,
    required this.isHardwareWallet,
    this.allowMultiSelect = false,
    this.constrainBip39Only = false,
    this.preselectedTypes,
    this.credentials,
  });
}
