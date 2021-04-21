import 'package:flutter/foundation.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';

class SideShiftRequest extends TradeRequest {
  SideShiftRequest(
      {@required this.depositMethod,
      @required this.settleMethod,
      @required this.settleAddress,
      @required this.depositAmount,
      @required this.refundAddress});

  CryptoCurrency depositMethod;
  CryptoCurrency settleMethod;
  String settleAddress;
  String depositAmount;
  String refundAddress;
}
