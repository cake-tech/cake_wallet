import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cw_core/crypto_currency.dart';

class TrocadorRequest extends TradeRequest {
  TrocadorRequest(
      {required this.from,
      required this.to,
      required this.address,
      required this.fromAmount,
      required this.toAmount,
      required this.refundAddress,
      required this.isReverse});

  CryptoCurrency from;
  CryptoCurrency to;
  String address;
  String fromAmount;
  String toAmount;
  String refundAddress;
  bool isReverse;
}
