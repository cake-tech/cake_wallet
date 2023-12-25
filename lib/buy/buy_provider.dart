import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';

abstract class BuyProvider {
  BuyProvider({
    required this.wallet,
    required this.isTestEnvironment,
  });

  final WalletBase wallet;
  final bool isTestEnvironment;

  String get title;

  String get buyOptionDescription;

  String get sellOptionDescription;

  String get lightIcon;

  String get darkIcon;

  @override
  String toString() => title;

  Future<void> launchProvider(BuildContext context, bool? isBuyAction);
}
