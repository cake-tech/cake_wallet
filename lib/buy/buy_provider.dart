import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
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

  bool get isAggregator;

  @override
  String toString() => title;

  Future<void>? launchProvider(
          {required BuildContext context,
          required Quote quote,
          required double amount,
          required bool isBuyAction,
          required String cryptoCurrencyAddress,
          String? countryCode}) =>
      null;

  Future<String> requestUrl(String amount, String sourceCurrency) => throw UnimplementedError();

  Future<Order> findOrderById(String id) => throw UnimplementedError();

  Future<BuyAmount> calculateAmount(String amount, String sourceCurrency) =>
      throw UnimplementedError();

  Future<List<PaymentMethod>> getAvailablePaymentTypes(
          String fiatCurrency, String cryptoCurrency, bool isBuyAction) async =>
      [];

  Future<List<Quote>?> fetchQuote(
          {required CryptoCurrency cryptoCurrency,
          required FiatCurrency fiatCurrency,
          required double amount,
          required bool isBuyAction,
          required String walletAddress,
          PaymentType? paymentType,
          String? countryCode}) async =>
      null;
}
