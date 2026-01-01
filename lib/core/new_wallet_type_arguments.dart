import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletTypeArguments {
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final bool isCreate;
  final bool inGroup;
  final Set<WalletType> preselectedTypes;
  final Object? credentials;
  final HardwareWalletType? hardwareWalletType;
  final String? walletGroupKey;

  NewWalletTypeArguments({
    this.onTypeSelected,
    this.isCreate = true,
    required this.inGroup,
    this.preselectedTypes = const {},
    this.credentials,
    this.hardwareWalletType,
    this.walletGroupKey,
  });
}
