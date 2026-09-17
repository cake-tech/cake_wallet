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
    this.chainPillLabel,
    this.chainBadgePath,
  });

  final CryptoCurrency currency;
  final bool isSelected;
  final Widget trailing;
  final VoidCallback onTap;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: _IconWithBadge(currency: currency, badgePath: chainBadgePath),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          currency.fullName ?? currency.title,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      if (chainPillLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chainPillLabel!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colors.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isSelected ? colors.primary : colors.onSurfaceVariant,
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
      size: 32,
      errorWidget: Container(
        width: 32,
        height: 32,
        child: Center(
          child: Text(
            currency.title.length >= 2 ? currency.title.substring(0, 2) : currency.title,
          ),
        ),
      ),
    );
    if (badgePath == null) return icon;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  width: 2,
                ),
                color: Theme.of(context).colorScheme.onSurface,
              ),
              padding: const EdgeInsets.all(2),
              child: CakeImageWidget(
                imageUrl: badgePath,
                color: Theme.of(context).colorScheme.surface,
                width: 13,
                height: 13,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
