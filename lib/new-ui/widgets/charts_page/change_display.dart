import 'package:cake_wallet/new-ui/model/charts/util/price_change_direction.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/change_pill.dart';
import 'package:flutter/material.dart';

class ChangeDisplay extends StatelessWidget {
  const ChangeDisplay(
      {super.key,
        required this.changeAmount,
        required this.changePercentage,
        required this.direction,
        required this.ticker});

  final String changeAmount;
  final String changePercentage;
  final String ticker;
  final PriceChangeDirection direction;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Text(
          "${direction.symbol}${ticker} ${changeAmount}",
          style: TextStyle(fontSize: 16, color: direction.color),
        ),
        ChangePill(changePercentage: changePercentage, direction: direction)
      ],
    );
  }
}