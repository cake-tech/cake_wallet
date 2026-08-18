import "package:cake_wallet/new-ui/widgets/money/currency_symbol_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class ReceiveTokenDisplay extends StatelessWidget {
  const ReceiveTokenDisplay({
    required this.token,
    required this.walletType,
    super.key,
  });

  final CryptoCurrency token;
  final WalletType walletType;

  @override
  Widget build(BuildContext context) {
    final chainAsset =
        walletType == WalletType.bsc ? "bnb" : walletTypeToString(walletType).toLowerCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        CurrencySymbolText(
          token,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99999),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              spacing: 4,
              children: [
                CakeImageWidget(
                  imageUrl: "assets/new-ui/chain_badges/$chainAsset.svg",
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                Text(
                  walletTypeToString(walletType),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
