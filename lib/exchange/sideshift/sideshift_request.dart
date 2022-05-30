import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cw_core/crypto_currency.dart';

class SideShiftRequest extends TradeRequest {
  final CryptoCurrency depositMethod;
  final CryptoCurrency settleMethod;
  final String depositAmount;
  final String settleAddress;
  final String refundAddress;

  SideShiftRequest(
      {this.depositMethod,
      this.settleMethod,
      this.depositAmount,
      this.settleAddress,
      this.refundAddress,});
}
