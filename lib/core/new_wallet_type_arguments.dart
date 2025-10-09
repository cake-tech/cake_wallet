import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletTypeArguments {
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final bool isCreate;
  final HardwareWalletType? hardwareWalletType;

  NewWalletTypeArguments({
    required this.onTypeSelected,
    required this.isCreate,
    this.hardwareWalletType,
  });
}
