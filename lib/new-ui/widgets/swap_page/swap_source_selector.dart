import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class SwapSourceSelector extends StatelessWidget {
  const SwapSourceSelector({
    required this.currencyIconPath,
    required this.currencyLabel,
    required this.availableBalance,
    required this.onTap,
    this.chainIconPath,
    this.walletName,
    super.key,
  });

  final String currencyIconPath;
  final String currencyLabel;
  final String availableBalance;
  final VoidCallback onTap;
  final String? chainIconPath;
  final String? walletName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chainIcon = chainIconPath;

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CakeImageWidget(
                  imageUrl: currencyIconPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  currencyLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: -0.08),
                ),
                if (chainIcon != null && chainIcon.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  CakeImageWidget(
                    imageUrl: chainIcon,
                    width: 12,
                    height: 12,
                    colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                  ),
                ],
                const Spacer(),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/wallet_filled.svg",
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        walletName ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.06,
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context).available_balance_short(availableBalance),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.06,
                      color: colors.primary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
