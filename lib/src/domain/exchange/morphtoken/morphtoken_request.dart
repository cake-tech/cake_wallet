import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';

class MorphTokenRequest extends TradeRequest {
  MorphTokenRequest(
      {@required this.from,
        @required this.to,
        @required this.address,
        @required this.amount,
        @required this.refundAddress});

  CryptoCurrency from;
  CryptoCurrency to;
  String address;
  String amount;
  String refundAddress;
}
