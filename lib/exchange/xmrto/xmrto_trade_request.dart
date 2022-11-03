import 'package:flutter/foundation.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';

class XMRTOTradeRequest extends TradeRequest {
  XMRTOTradeRequest(
      {required this.from,
      required this.to,
      required this.amount,
      required this.receiveAmount,
      required this.address,
      required this.refundAddress,
      required this.isBTCRequest});

  final CryptoCurrency from;
  final CryptoCurrency to;
  final String amount;
  final String receiveAmount;
  final String address;
  final String refundAddress;
  final bool isBTCRequest;
}
