import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class ReceiveLargeAmountPreview extends StatelessWidget {
  const ReceiveLargeAmountPreview({
    required this.amount,
    required this.currencySymbol,
    required this.largeQrMode,
    super.key,
  });

  final Money? amount;
  final String currencySymbol;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        opacity: largeQrMode && amount != null ? 1 : 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transformAlignment: Alignment.bottomCenter,
          height: largeQrMode && amount != null ? 52 : 0,
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              CakeImageWidget(
                imageUrl: "assets/new-ui/send.svg",
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurfaceVariant,
                  BlendMode.srcIn,
                ),
              ),
              if (amount != null)
                Row(
                  spacing: 4,
                  children: [
                    MoneyText(
                      amount!,
                      showSymbol: false,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      currencySymbol,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
}
