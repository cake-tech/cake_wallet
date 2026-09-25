import "package:cake_wallet/new-ui/model/charts/util/price_change_direction.dart";
import "package:flutter/material.dart";

class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.changePercentage, required this.direction});

  final String changePercentage;
  final PriceChangeDirection direction;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: direction.color.withAlpha(52), borderRadius: BorderRadius.circular(999999)),
      child: Padding(
        padding: const EdgeInsets.only(top: 2.5, bottom: 2.5, left: 4, right: 8),
        child: Text(
          "${direction.symbol} $changePercentage%",
          style: TextStyle(color: direction.color),
        ),
      ));
}
