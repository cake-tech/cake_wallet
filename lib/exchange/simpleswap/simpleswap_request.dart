import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class SimpleSwapRequest extends TradeRequest {
  SimpleSwapRequest({
    required this.from,
    required this.to,
    required this.address,
    required this.amount,
    required this.refundAddress,
    this.toAmount = ''
  });

  CryptoCurrency from;
  CryptoCurrency to;
  String address;
  String amount;
  String toAmount;
  String refundAddress;
}
