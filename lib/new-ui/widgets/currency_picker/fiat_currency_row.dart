import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class FiatCurrencyRow extends StatelessWidget {
  const FiatCurrencyRow({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  final FiatCurrency currency;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CakeImageWidget(
                imageUrl: 'assets/images/flags/${currency.countryCode}.png',
                width: 28,
                height: 20,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: 28,
                  height: 20,
                  color: colors.surfaceContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currency.fullName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check, size: 20, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
