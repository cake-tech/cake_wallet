import 'package:cake_wallet/new-ui/model/charts/price_data.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_change_direction.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceChart extends StatelessWidget {
  const PriceChart(
      {super.key,
      required this.height,
      required this.prices,
      required this.direction,
      required this.touchCallback});

  final List<PriceData> prices;
  final double height;
  final PriceChangeDirection direction;
  final Function(FlTouchEvent, LineTouchResponse?) touchCallback;

  @override
  Widget build(BuildContext context) {
    final chartPoints = prices.map((entry) {
      final x = entry.time.millisecondsSinceEpoch.toDouble();
      final y = double.parse(entry.price);
      return FlSpot(x, y);
    }).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartPoints,
              gradient: LinearGradient(colors: [direction.color.withAlpha(25), direction.color]),
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
              enabled: true,
              getTouchLineStart: (barData, spotIndex) => -double.infinity,
              getTouchLineEnd: (barData, spotIndex) => double.infinity,
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      strokeWidth: 1,
                      color: direction.color.withAlpha(80),
                      dashArray: [4, 4],
                    ),
                    FlDotData(),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) => null).toList();
                },
              ),
              touchCallback: touchCallback),
        ),
      ),
    );
  }
}
