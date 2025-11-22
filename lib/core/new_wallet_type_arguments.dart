import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletTypeArguments {
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final bool isCreate;
  final bool allowMultiSelect;
  final bool constrainBip39Only;
  final Set<WalletType> preselectedTypes;
  final Object? credentials;
  final HardwareWalletType? hardwareWalletType;
  final String? walletGroupKey;

  NewWalletTypeArguments({
    required this.onTypeSelected,
    required this.isCreate,
    this.allowMultiSelect = false,
    this.constrainBip39Only = false,
    this.preselectedTypes = const {},
    this.credentials,
    this.hardwareWalletType,
    this.walletGroupKey,
  });
}
