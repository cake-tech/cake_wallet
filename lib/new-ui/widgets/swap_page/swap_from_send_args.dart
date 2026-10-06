import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class SwapFromSendArgs {
  const SwapFromSendArgs({
    required this.recipientAddress,
    required this.receiveCurrency,
    this.receiveAmount,
  });

  factory SwapFromSendArgs.fromIntent(AnyPaySwapIntent intent) => SwapFromSendArgs(
        recipientAddress: intent.recipientAddress,
        receiveCurrency: intent.receiveCurrency,
        receiveAmount: intent.receiveAmount,
      );

  final String recipientAddress;
  final CryptoCurrency receiveCurrency;
  final Money? receiveAmount;
}
