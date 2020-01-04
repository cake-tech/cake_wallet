import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';

class XMRTOTradeRequest extends TradeRequest {
  final CryptoCurrency from;
  final CryptoCurrency to;
  final String amount;
  final String address;
  final String refundAddress;

  XMRTOTradeRequest(
      {@required this.from,
      @required this.to,
      @required this.amount,
      @required this.address,
      @required this.refundAddress});
}
