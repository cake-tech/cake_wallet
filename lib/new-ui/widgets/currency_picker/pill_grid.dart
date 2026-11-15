import "package:cake_wallet/generated/i18n.dart";
import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class PillGrid extends StatelessWidget {
  const PillGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
    required this.symbolResolver,
    this.onSeeAll,
  });

  final List<CryptoCurrency> items;
  final CryptoCurrency? selected;
  final ValueChanged<CryptoCurrency> onTap;
  final String Function(CryptoCurrency c) symbolResolver;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;
        final onSeeAll = this.onSeeAll;
        final colors = Theme.of(context).colorScheme;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _PillCard(
                  leading: TokenImageWidget(imageUrl: item.iconPath ?? "", size: 24),
                  isSelected: selected != null && selected == item,
                  label: symbolResolver(item),
                  onTap: () => onTap(item),
                ),
              ),
            if (onSeeAll != null)
              SizedBox(
                width: cardWidth,
                child: _PillCard(
                  leading: CakeImageWidget(
                    imageUrl: "assets/new-ui/dots_grid.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                  ),
                  isSelected: false,
                  label: S.of(context).picker_see_all,
                  textColor: colors.primary,
                  onTap: onSeeAll,
                ),
              ),
          ],
        );
      },
    );
}

class _PillCard extends StatelessWidget {
  const _PillCard({
    required this.leading,
    required this.isSelected,
    required this.label,
    required this.onTap,
    this.textColor,
  });

  final Widget leading;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.only(left: 6, right: 8),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: colors.primary, width: 1.5) : null,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.06,
                    ),
              ),
            ),
            SizedBox(
              width: 12,
              height: 12,
              child: Center(
                child: CakeImageWidget(
                  imageUrl: "assets/new-ui/arrow_right.svg",
                  width: 5,
                  height: 9,
                  colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
