import 'package:flutter/foundation.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';

class ExolixRequest extends TradeRequest {
  ExolixRequest(
      {required this.from,
      required this.to,
      required this.address,
      required this.fromAmount,
      required this.toAmount,
      required this.refundAddress});

  CryptoCurrency from;
  CryptoCurrency to;
  String address;
  String fromAmount;
  String toAmount;
  String refundAddress;
}
