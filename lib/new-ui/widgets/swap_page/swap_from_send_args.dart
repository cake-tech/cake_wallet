import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
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

  factory SwapFromSendArgs.fromIntent(
    AnyPaySwapIntent intent,
    BalanceViewModel balanceViewModel, {
    required bool isFiatDisabled,
  }) {
    final depositBalanceByAsset = <CryptoCurrency, CurrencyPickerBalance>{
      for (final r in balanceViewModel.formattedBalances)
        r.asset: CurrencyPickerBalance(
          amount: "${r.availableBalance} ${r.asset.title}",
          fiat: isFiatDisabled ? null : "${r.fiatAvailableBalanceRaw} ${r.fiatCurrency?.symbol}",
          fiatValue: isFiatDisabled ? null : double.tryParse(r.fiatAvailableBalanceRaw),
        ),
    };

    return SwapFromSendArgs(
      recipientAddress: intent.recipientAddress,
      receiveCurrency: intent.receiveCurrency,
      targetWalletType: intent.targetWalletType,
      depositBalanceByAsset: depositBalanceByAsset,
      receiveAmount: intent.receiveAmount,
    );
  }

  final String recipientAddress;
  final CryptoCurrency receiveCurrency;
  final WalletType targetWalletType;
  final Map<CryptoCurrency, CurrencyPickerBalance>? depositBalanceByAsset;
  final Money? receiveAmount;
}
