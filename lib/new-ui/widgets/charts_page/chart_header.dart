import 'package:cake_wallet/new-ui/model/charts/util/chart_range.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_change_direction.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/change_display.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/chart_view.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/coin_header.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/price_header.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/range_selector.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

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