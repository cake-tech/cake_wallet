import 'package:cake_wallet/new-ui/viewmodels/charts/util/price_change_direction.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/change_pill.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';

class ChartsAssetGrid extends StatelessWidget {
  const ChartsAssetGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 100),
        itemBuilder: (context, index) => ChartsAssetCard(
            currency: CryptoCurrency.btc,
            price: "355.87",
            ticker: "USD",
            changePercentage: "4.56",
            direction: PriceChangeDirection.up));
  }
}

class ChartsAssetCard extends StatelessWidget {
  const ChartsAssetCard(
      {super.key,
      required this.currency,
      required this.price,
      required this.ticker,
      required this.changePercentage,
      required this.direction});

  final CryptoCurrency currency;
  final String price;
  final String ticker;
  final String changePercentage;
  final PriceChangeDirection direction;

  String get displayPrice {
    final priceDouble = double.parse(price);
    if (priceDouble > 10000)
      return priceDouble.toStringAsFixed(0);
    else
      return priceDouble.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(width: 1, color: Theme.of(context).colorScheme.surfaceContainerHighest),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 5,
                      children: [
                        RotatedBox(
                          quarterTurns: direction == PriceChangeDirection.up ? 0 : 2,
                          child: CakeImageWidget(
                            imageUrl: "assets/new-ui/price_change_arrow.svg",
                            width: 8,
                            height: 8,
                            colorFilter: ColorFilter.mode(direction.color, BlendMode.srcIn),
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
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    )
                  ],
                ),
                ChangePill(changePercentage: changePercentage, direction: direction)
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                CakeImageWidget(
                  imageUrl: currency.iconSvgPath ?? currency.iconPath,
                  width: 24,
                  height: 24,
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
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
    );
  }
}
