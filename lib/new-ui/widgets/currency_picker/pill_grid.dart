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
  });

  final List<CryptoCurrency> items;
  final CryptoCurrency? selected;
  final ValueChanged<CryptoCurrency> onTap;
  final String Function(CryptoCurrency c) symbolResolver;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _PillCard(
                  currency: item,
                  isSelected: selected != null && selected == item,
                  label: symbolResolver(item),
                  onTap: () => onTap(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PillCard extends StatelessWidget {
  const _PillCard({
    required this.currency,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  final CryptoCurrency currency;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(80),
          border: isSelected ? Border.all(color: colors.primary, width: 1.5) : null,
        ),
        child: Row(
          children: [
            TokenImageWidget(
              imageUrl: currency.iconPath ?? '',
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
