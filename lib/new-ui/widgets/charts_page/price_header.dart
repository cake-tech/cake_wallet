import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:flutter/material.dart";

class ChartViewPriceHeader extends StatelessWidget {
  const ChartViewPriceHeader({
    required this.price,
    required this.fiatCurrency,
    required this.highlight,
    super.key,
  });

  final String price;
  final FiatCurrency? fiatCurrency;
  final bool highlight;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          spacing: 6,
          children: [
            if (fiatCurrency != null)
              Text(
                fiatCurrency!.sign,
                style: TextStyle(
                  fontSize: 36,
                  color: highlight
                      ? Theme.of(context).colorScheme.primary.withAlpha(128)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              double.tryParse(price) == null
                  ? price
                  : price.withLocalSeperator(getIt.get<AppStore>().settingsStore.languageCode),
              style: TextStyle(
                fontSize: 36,
                fontFamily: "IBM Plex Sans",
                fontFeatures: const [FontFeature.tabularFigures()],
                color: highlight
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
}
