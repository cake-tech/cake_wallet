import "package:auto_size_text/auto_size_text.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/provider_selector_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/exchange/exchange_view_model.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class AnyPaySwapFooter extends StatelessWidget {
  const AnyPaySwapFooter({required this.exchangeViewModel, super.key});

  final ExchangeViewModel exchangeViewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Observer(
      builder: (_) {
        if (exchangeViewModel.depositAmount.isEmpty) {
          return const SizedBox.shrink();
        }

        final provider = exchangeViewModel.forcedProvider ?? exchangeViewModel.providerDisplay;
        final depositAmount = exchangeViewModel.depositAmount;
        final depositSymbol =
            exchangeViewModel.amountParsingProxy.getCryptoSymbol(exchangeViewModel.depositCurrency);
        final depositFiat = exchangeViewModel.roundedDepositAmountFiat(2);
        final showFiat = !exchangeViewModel.isFiatDisabled && depositFiat.isNotEmpty;
        return Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.primary),
                ),
                child: AutoSizeText.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: "$depositAmount $depositSymbol"),
                      if (showFiat)
                        TextSpan(
                          text: "  ≈ ${exchangeViewModel.fiat.symbol}$depositFiat",
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  minFontSize: 10,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.06),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: provider == null
                  ? null
                  : () => Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (context) => Material(
                            child: ProviderSelectorPage(exchangeViewModel: exchangeViewModel),
                          ),
                        ),
                      ),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider != null)
                      CakeImageWidget(imageUrl: provider.description.image, width: 24, height: 24)
                    else
                      const CupertinoActivityIndicator(),
                    const SizedBox(width: 8),
                    Text(
                      provider?.title ?? "${S.of(context).finding_provider}...",
                      style: textTheme.bodyMedium?.copyWith(letterSpacing: -0.07),
                    ),
                    const SizedBox(width: 8),
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/chooser.svg",
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
