import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cw_core/crypto_currency.dart';

class SideShiftRequest extends TradeRequest {
  SideShiftRequest(
      {required this.depositMethod,
      required this.settleMethod,
      required this.depositAmount,
      required this.settleAddress,
      required this.refundAddress});

  final CryptoCurrency depositMethod;
  final CryptoCurrency settleMethod;
  final String depositAmount;
  final String settleAddress;
  final String refundAddress;
}
