import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";

class SwapFromSendArgs {
  const SwapFromSendArgs({
    required this.recipientAddress,
    required this.receiveCurrency,
    required this.targetWalletType,
    this.depositBalanceByAsset,
    this.receiveAmount,
  });

  final String recipientAddress;
  final CryptoCurrency receiveCurrency;
  final WalletType targetWalletType;
  final Map<CryptoCurrency, CurrencyPickerBalance>? depositBalanceByAsset;
  final Money? receiveAmount;
}
