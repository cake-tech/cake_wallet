import 'package:cake_wallet/new-ui/viewmodels/charts/util/price_change_direction.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';




Map<DateTime, String> get chartMockData {
  final DateTime now = DateTime.now();

  return {
    now.subtract(const Duration(hours: 24, minutes: 0)): "120.50",
    now.subtract(const Duration(hours: 23, minutes: 15)): "135.20",
    now.subtract(const Duration(hours: 22, minutes: 30)): "105.00",
    now.subtract(const Duration(hours: 21, minutes: 45)): "160.75",
    now.subtract(const Duration(hours: 21, minutes: 0)): "140.00",
    now.subtract(const Duration(hours: 20, minutes: 15)): "210.25",
    now.subtract(const Duration(hours: 19, minutes: 30)): "185.50",
    now.subtract(const Duration(hours: 18, minutes: 45)): "300.00",
    now.subtract(const Duration(hours: 18, minutes: 0)): "250.50",
    now.subtract(const Duration(hours: 17, minutes: 15)): "310.00",
    now.subtract(const Duration(hours: 16, minutes: 30)): "310.00",
    now.subtract(const Duration(hours: 15, minutes: 45)): "220.25",
    now.subtract(const Duration(hours: 15, minutes: 0)): "300.50",
    now.subtract(const Duration(hours: 14, minutes: 15)): "260.00",
    now.subtract(const Duration(hours: 13, minutes: 30)): "280.75",
    now.subtract(const Duration(hours: 12, minutes: 45)): "265.00",
    now.subtract(const Duration(hours: 12, minutes: 0)): "245.50",
    now.subtract(const Duration(hours: 11, minutes: 15)): "245.50",
    now.subtract(const Duration(hours: 10, minutes: 30)): "300.00",
    now.subtract(const Duration(hours: 9, minutes: 45)): "270.25",
    now.subtract(const Duration(hours: 9, minutes: 0)): "300.00",
    now.subtract(const Duration(hours: 8, minutes: 15)): "250.50",
    now.subtract(const Duration(hours: 7, minutes: 30)): "270.00",
    now.subtract(const Duration(hours: 6, minutes: 45)): "235.75",
    now.subtract(const Duration(hours: 6, minutes: 0)): "280.00",
    now.subtract(const Duration(hours: 5, minutes: 15)): "320.50",
    now.subtract(const Duration(hours: 4, minutes: 30)): "295.00",
    now.subtract(const Duration(hours: 3, minutes: 45)): "340.25",
    now.subtract(const Duration(hours: 3, minutes: 0)): "250.00",
    now.subtract(const Duration(hours: 2, minutes: 15)): "280.50",
    now.subtract(const Duration(hours: 1, minutes: 30)): "255.00",
    now.subtract(const Duration(hours: 0, minutes: 45)): "270.25",
    now: "285.50",
  };
}

class PriceChart extends StatelessWidget {
  const PriceChart(
      {super.key,
      required this.height,
      required this.prices,
      required this.direction,
      required this.touchCallback});

  final Map<DateTime, String> prices;
  final double height;
  final PriceChangeDirection direction;
  final Function(FlTouchEvent, LineTouchResponse?) touchCallback;

  @override
  Widget build(BuildContext context) {
    final chartPoints = chartMockData.entries.map((entry) {
      final x = entry.key.millisecondsSinceEpoch.toDouble();
      final y = double.parse(entry.value);
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
              gradient:
              LinearGradient(colors: [direction.color.withAlpha(25), direction.color]),
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
              enabled: true,
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: Colors.transparent,
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
