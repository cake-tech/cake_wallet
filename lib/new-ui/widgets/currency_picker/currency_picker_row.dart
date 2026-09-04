import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class CurrencyPickerRow extends StatelessWidget {
  const CurrencyPickerRow({
    super.key,
    required this.currency,
    required this.isSelected,
    required this.trailing,
    required this.onTap,
    this.subtitle,
    this.chainPillLabel,
    this.chainBadgePath,
  });

  final CryptoCurrency currency;
  final bool isSelected;
  final Widget trailing;
  final VoidCallback onTap;
  final String? subtitle;
  final String? chainPillLabel;
  final String? chainBadgePath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: subtitle == null ? 48 : 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: _IconWithBadge(currency: currency, badgePath: chainBadgePath),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currency.fullName ?? currency.title,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(letterSpacing: -0.07),
                            ),
                          ),
                          if (chainPillLabel != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                chainPillLabel!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.06,
                                      color: colors.primary,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                letterSpacing: -0.06,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
                const SizedBox(width: 4),
                ExcludeSemantics(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Center(
                      child: CakeImageWidget(
                        imageUrl: "assets/new-ui/arrow_right.svg",
                        width: 7,
                        height: 12,
                        colorFilter: ColorFilter.mode(
                          isSelected ? colors.primary : colors.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({required this.currency, required this.badgePath});

  final CryptoCurrency currency;
  final String? badgePath;

  @override
  Widget build(BuildContext context) {
    final icon = TokenImageWidget(
      imageUrl: currency.iconPath ?? '',
      size: 28,
      errorWidget: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Text(
            currency.title.length >= 2 ? currency.title.substring(0, 2) : currency.title,
          ),
        ),
      ),
    );
    if (badgePath == null) {
      return icon;
    }
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          icon,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.onSurface,
              ),
              child: CakeImageWidget(
                imageUrl: badgePath,
                color: Theme.of(context).colorScheme.surface,
                width: 6,
                height: 6,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
