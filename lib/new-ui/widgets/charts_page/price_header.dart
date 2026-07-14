import 'package:flutter/material.dart';

class ChartViewPriceHeader extends StatelessWidget {
  const ChartViewPriceHeader({
    super.key,
    required this.price,
    required this.ticker,
    required this.highlight,
  });

  final String price;
  final String ticker;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        spacing: 6,
        children: [
          Text(
            price,
            style: TextStyle(
                fontSize: 36,
                color: highlight
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            ticker,
            style: TextStyle(
                fontSize: 36,
                color: highlight
                    ? Theme.of(context).colorScheme.primary.withAlpha(128)
                    : Theme.of(context).colorScheme.onSurfaceVariant),
          )
        ],
      ),
    );
  }
}
