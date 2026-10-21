import "package:cake_wallet/exchange/rate_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class TradeRequest {
  TradeRequest({
    required this.refundAddress,
    required this.payoutAddress,
    required this.depositAmount,
    required this.payoutAmount,
    required this.isFixedRate,
    String? toAddressExtraId,
    // providers really don't like when you send an empty extraId, so we make it null
  }) : toAddressExtraId = toAddressExtraId?.isEmpty ?? false ? null : toAddressExtraId;

  final String refundAddress;
  final String payoutAddress;
  final Money depositAmount;
  final Money payoutAmount;
  final String? toAddressExtraId;
  final bool isFixedRate;

  CryptoCurrency get depositCurrency => depositAmount.currency as CryptoCurrency;

  CryptoCurrency get payoutCurrency => payoutAmount.currency as CryptoCurrency;

  RateRequest get rateRequest => isFixedRate
      ? FixedRateRequest(depositCurrency: depositCurrency, payoutAmount: payoutAmount)
      : FloatingRateRequest(depositAmount: depositAmount, payoutCurrency: payoutCurrency);

  Map<String, dynamic> toJson() => {
      "refundAddress": refundAddress,
      "payoutAddress": payoutAddress,
      "depositAmount": depositAmount.serialized,
      "payoutAmount": payoutAmount.serialized,
      "toAddressExtraId": toAddressExtraId,
      "isFixedRate": isFixedRate,
    };
}
