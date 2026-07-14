import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class ChartViewCoinHeader extends StatelessWidget {
  const ChartViewCoinHeader({super.key, required this.currency, required this.isFavorite});

  final CryptoCurrency currency;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isFavorite ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            if (isFavorite)
              CakeImageWidget(
                imageUrl: currency.iconPath ?? "",
                width: 30,
                height: 30,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
      ],
    );
  }
}
