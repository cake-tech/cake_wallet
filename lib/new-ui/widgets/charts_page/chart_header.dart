import 'package:cake_wallet/new-ui/viewmodels/charts/charts_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/change_display.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/chart_view.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/coin_header.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/price_header.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/range_selector.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChartHeader extends StatefulWidget {
  const ChartHeader(
      {super.key,
      required this.currency,
      required this.chartHeight,
      required this.chartPadding,
      required this.centered,
      required this.favorite});

  final CryptoCurrency currency;
  final double chartHeight;
  final double chartPadding;
  final bool centered;
  final bool favorite;

  @override
  State<ChartHeader> createState() => _ChartHeaderState();
}

class _ChartHeaderState extends State<ChartHeader> {
  String? _viewedPrice;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChartsBloc, ChartsState>(
      builder: (context, state) {
        if (state case ChartsStateWithData s) {
          return Column(
            crossAxisAlignment:
                widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment:
                      widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    if (!widget.favorite)
                      CakeImageWidget(
                        imageUrl: widget.currency.iconSvgPath ?? widget.currency.iconPath ?? "",
                        width: 60,
                        height: 60,
                      ),
                    ChartViewCoinHeader(currency: widget.currency, isFavorite: widget.favorite),
                    ChartViewPriceHeader(
                      price: _viewedPrice ?? s.priceDisplayStringFor(widget.currency),
                      ticker: s.fiatTicker,
                      highlight: _viewedPrice != null,
                    ),
                    Column(
                      crossAxisAlignment:
                          widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          // has to be constant-size, otherwise will jump around when loading
                          height: 36,
                          child: (s is ChartsLoaded)
                              ? ChangeDisplay(
                                  changeData: s.changeDataFor(widget.currency), ticker: s.fiatTicker)
                              : SizedBox.shrink(),
                        ),
                        if (s is ChartsLoaded)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: widget.chartPadding),
                            child: PriceChart(
                              height: widget.chartHeight,
                              prices: s.dataFor(widget.currency),
                              direction: s.changeDataFor(widget.currency).direction,
                              touchCallback: (event, response) {
                                if (!event.isInterestedForInteractions) {
                                  setState(() {
                                    _viewedPrice = null;
                                  });
                                  return;
                                }

                                final newPrice =
                                    response?.lineBarSpots?.firstOrNull?.y.toStringAsFixed(2);
                                if (_viewedPrice != newPrice) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _viewedPrice = newPrice;
                                  });
                                }
                              },
                            ),
                          )
                        else
                          SizedBox(
                              height: widget.chartHeight + widget.chartPadding * 2,
                              child: Center(child: CupertinoActivityIndicator())),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 1,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChartRangeSelector(
                      selectedRange: s.range,
                      onRangeSelected: (range) =>
                          context.read<ChartsBloc>().add(RangeChanged(newRange: range)))
                ],
              )
            ],
          );
        }
        return CupertinoActivityIndicator();
      },
    );
  }
}
