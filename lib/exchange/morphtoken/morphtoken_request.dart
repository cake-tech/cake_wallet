import 'package:flutter/foundation.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';

class MorphTokenRequest extends TradeRequest {
  MorphTokenRequest(
      {required this.from,
        required this.to,
        required this.address,
        required this.amount,
        required this.refundAddress});

  CryptoCurrency from;
  CryptoCurrency to;
  String address;
  String amount;
  String refundAddress;
}
