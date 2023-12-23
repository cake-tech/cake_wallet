import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

abstract class BuyProvider {
  BuyProvider({
    required this.wallet,
    required this.isTestEnvironment,
  }) {
    allBuyProviders.add(this);
  }

  final WalletBase wallet;
  final bool isTestEnvironment;

  String get title;

  String get buyOptionDescription;

  String get sellOptionDescription;

  String get lightIcon;

  String get darkIcon;

  bool get isBuyOptionAvailable;

  bool get isSellOptionAvailable;

  static final List<BuyProvider> allBuyProviders = [];

  @override
  String toString() => title;

  Future<void> launchProvider(BuildContext context, bool? isBuyAction);
}
