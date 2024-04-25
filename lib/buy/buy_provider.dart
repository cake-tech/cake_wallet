import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';

abstract class BuyProvider {
  BuyProvider({
    required this.wallet,
    required this.isTestEnvironment,
    required this.ledgerVM,
  });

  final WalletBase wallet;
  final bool isTestEnvironment;
  final LedgerViewModel? ledgerVM;

  String get title;

  String get providerDescription;

  String get lightIcon;

  String get darkIcon;

  @override
  String toString() => title;

  Future<void> launchProvider(BuildContext context, bool? isBuyAction);

  Future<String> requestUrl(String amount, String sourceCurrency) => throw UnimplementedError();

  Future<Order> findOrderById(String id) => throw UnimplementedError();

  Future<BuyAmount> calculateAmount(String amount, String sourceCurrency) => throw UnimplementedError();
}
