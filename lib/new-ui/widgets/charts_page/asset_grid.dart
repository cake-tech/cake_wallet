import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/long_press_menu/long_press_footer.dart';
import 'package:cake_wallet/new-ui/widgets/long_press_menu/long_press_popup.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_change_data.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_change_direction.dart';
import 'package:cake_wallet/new-ui/viewmodels/charts/charts_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/change_pill.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/chart_modal.dart';
import 'package:cake_wallet/new-ui/widgets/long_press_menu/long_press_menu.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChartsAssetGrid extends StatelessWidget {
  const ChartsAssetGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChartsBloc, ChartsState>(
      builder: (context, state) {
        if (state is ChartsStateWithData) {
          final currencies = state.currencies;
          return GridView.builder(
            shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: currencies.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 105),
              itemBuilder: (context, index) {
                final curr = currencies[index];
                return ChartsAssetCard(
                  currency: curr,
                  price: state.priceDisplayStringFor(curr),
                  ticker: state.fiatTicker,
                  changeData: state is ChartsLoaded ? state.changeDataFor(curr) : null,
                  favorite: curr == state.pinnedCurrency,
                  isSingleCurrency: state.hasSingleCurrency,
                );
              });
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}

class ChartsAssetCard extends StatelessWidget {
  const ChartsAssetCard(
      {super.key,
      required this.currency,
      required this.price,
      required this.ticker,
      this.changeData,
      required this.favorite,
      required this.isSingleCurrency});

  final CryptoCurrency currency;
  final String price;
  final String ticker;
  final PriceChangeData? changeData;
  final bool favorite;
  final bool isSingleCurrency;

  String get displayPrice {
    try {
      final priceDouble = double.parse(price);
      if (priceDouble > 10000)
        return priceDouble.toStringAsFixed(0);
      else
        return priceDouble.toStringAsFixed(2);
    } catch (_) {
      return price;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LongPressPopupBuilder(
      popup: LongPressMenu(items: [
        LongPressMenuItem(
            label: S.of(context).favorite,
            iconPath: "assets/new-ui/favorite.svg",
            onSelected: () {
              context.read<ChartsBloc>().add(CurrencyPinned(currency: currency));
              Navigator.of(context).pop();
            },
            color: favorite ? Theme.of(context).colorScheme.error : null),
        LongPressMenuItem(
            label: S.of(context).remove,
            iconPath: "assets/new-ui/address_hide.svg",
            onSelected: () {
              if (!isSingleCurrency) {
                context.read<ChartsBloc>().add(CurrencyRemoved(currency: currency));
                Navigator.of(context).pop();
              }
            },
            color: isSingleCurrency ? Theme.of(context).colorScheme.onSurfaceVariant : null)
      ]),
      footer:
          isSingleCurrency ? LongPressFooter(text: S.of(context).cannot_remove_last_asset) : null,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          final res = await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) => ChartModal(
                    currency: currency,
                    isFavorite: favorite,
                  ));
          if (res != null && res is bool && res) {
            context.read<ChartsBloc>().add(CurrencyPinned(currency: currency));
          }
        },
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  width: 1, color: Theme.of(context).colorScheme.surfaceContainerHighest),
              gradient: LinearGradient(colors: [
                context.customColors.cardGradientColorPrimary,
                context.customColors.cardGradientColorSecondary
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              spacing: 12,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 5,
                            children: [
                              if (changeData != null)
                                RotatedBox(
                                  quarterTurns:
                                      changeData!.direction == PriceChangeDirection.up ? 0 : 2,
                                  child: CakeImageWidget(
                                    imageUrl: "assets/new-ui/price_change_arrow.svg",
                                    width: 8,
                                    height: 8,
                                    colorFilter: ColorFilter.mode(
                                        changeData!.direction.color, BlendMode.srcIn),
                                  ),
                                ),
                              Text(
                                currency.title.toUpperCase(),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              )
                            ],
                          ),
                          Text(
                            currency.fullName ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          )
                        ],
                      ),
                    ),
                    if (changeData != null)
                      ChangePill(
                          changePercentage: changeData!.percentage,
                          direction: changeData!.direction)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    CakeImageWidget(
                      imageUrl: currency.iconPath,
                      width: 24,
                      height: 24,
                    ),
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerRight,
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 4,
                          children: [
                            Text(
                              displayPrice,
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                            ),
                            Text(
                              ticker,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
