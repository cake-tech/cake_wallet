import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_amount.dart";
import "package:cw_core/crypto_currency.dart";

class TradeRequest {
  TradeRequest({
    required this.refundAddress,
    required this.payoutAddress,
    required this.depositAmount,
    required this.payoutAmount,
    required this.isFixedRate,
    this.toAddressExtraId = "",
  });

  final String refundAddress;
  final SwapAddress payoutAddress;
  final SwapAmount depositAmount;
  final SwapAmount payoutAmount;
  final String toAddressExtraId;
  final bool isFixedRate;

  CryptoCurrency get depositCurrency => depositAmount.currency;
  CryptoCurrency get payoutCurrency => payoutAmount.currency;
}
