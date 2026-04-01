import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceChangeDirection {
  final Color color;
  final String symbol;

  const PriceChangeDirection._(this.color, this.symbol);

  static const up = PriceChangeDirection._(Color(0xFF6FC84E), "+");
  static const down = PriceChangeDirection._(Color(0xFFEA696F), "-");
}

class ChartRange {
  final Duration? duration;
  final String displayText;

  const ChartRange._(this.duration, this.displayText);

  static const oneHour = ChartRange._(Duration(hours: 1), "1H");
  static const oneDay = ChartRange._(Duration(days: 1), "1D");
  static const sevenDays = ChartRange._(Duration(days: 7), "7D");
  static const thirtyDays = ChartRange._(Duration(days: 30), "30D");
  static const oneYear = ChartRange._(Duration(days: 365), "1Y");
  static const all = ChartRange._(null, "ALL");

  static const ranges = [oneHour, oneDay, sevenDays, thirtyDays, oneYear, all];
}

class ChartRangeSelector extends StatelessWidget {
  const ChartRangeSelector({super.key, required this.selectedRange, required this.onRangeSelected});

  final ChartRange selectedRange;
  final Function(ChartRange) onRangeSelected;

  static const double optionSize = 36;
  static const double optionPadding = 24;
  static const Duration switchDuration = Duration(milliseconds: 250);

  double pillPosition(int selectedIndex) => selectedIndex * (optionSize + optionPadding);

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ChartRange.ranges.indexOf(selectedRange);

    return Stack(
      children: [
        AnimatedPositioned(
          curve: Curves.easeOutCubic,
            left: pillPosition(selectedIndex),
            child: Container(
              height: optionSize,
              width: optionSize,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
                  borderRadius: BorderRadius.circular(999999)),
            ),
            duration: switchDuration),
        Row(
          spacing: optionPadding,
          children: ChartRange.ranges.map((item) {
            final selected = selectedRange == item;
            return GestureDetector(
              onTap: ()=>onRangeSelected(item),
              child: Container(
                width: optionSize,
                height: optionSize,
                child: AnimatedDefaultTextStyle(
                    duration: switchDuration,
                    style: TextStyle(
                        fontWeight: selected ? FontWeight.w400 : FontWeight.w500,
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    child: Center(child: Text(item.displayText))),
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}

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

class ChartHeader extends StatefulWidget {
  const ChartHeader({super.key});

  @override
  State<ChartHeader> createState() => _ChartHeaderState();
}

class _ChartHeaderState extends State<ChartHeader> {
  String? _viewedPrice;
  ChartRange _range = ChartRange.oneDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            ChartViewCoinHeader(currency: CryptoCurrency.btc, isFavorite: true),
            ChartViewPriceHeader(
              price: _viewedPrice ?? "109437.05",
              ticker: "USD",
              highlight: _viewedPrice != null,
            ),
            Column(
              children: [
                ChangeDisplay(
                    changeAmount: "85.6",
                    changePercentage: "2.31",
                    direction: PriceChangeDirection.up,
                    ticker: "USD"),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22.0),
                  child: PriceChart(
                    height: 100,
                    prices: chartMockData,
                    direction: PriceChangeDirection.up,
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) {
                        setState(() {
                          _viewedPrice = null;
                        });
                        return;
                      }
                      setState(() {
                        _viewedPrice = response?.lineBarSpots?.firstOrNull?.y.toStringAsFixed(2);
                      });
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
                ),
                ChartRangeSelector(selectedRange: _range, onRangeSelected: (range)=>setState(() {
                  _range = range;
                }))
              ],
            )
          ],
        )
      ],
    );
  }
}

class ChartViewCoinHeader extends StatelessWidget {
  const ChartViewCoinHeader({super.key, required this.currency, required this.isFavorite});

  final CryptoCurrency currency;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          spacing: 10,
          children: [
            CakeImageWidget(
              imageUrl: currency.iconSvgPath ?? currency.iconPath ?? "",
              width: 30,
              height: 30,
            ),
            Row(
              spacing: 5,
              children: [
                Text(
                  currency.fullName ?? currency.title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999999),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                    child: Text(
                      currency.title,
                      style: TextStyle(
                          fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
        if (isFavorite)
          CakeImageWidget(
            imageUrl: "assets/new-ui/favorite.svg",
            width: 16,
            height: 16,
            colorFilter:
                ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
          )
        else
          SizedBox.shrink()
      ],
    );
  }
}

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
        Container(
            decoration: BoxDecoration(
                color: direction.color.withAlpha(52), borderRadius: BorderRadius.circular(999999)),
            child: Padding(
              padding: EdgeInsets.only(top: 2.5, bottom: 2.5, left: 4, right: 8),
              child: Text(
                "${direction.symbol} $changePercentage%",
                style: TextStyle(color: direction.color),
              ),
            ))
      ],
    );
  }
}
