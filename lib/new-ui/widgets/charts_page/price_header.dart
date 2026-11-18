import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

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
        child: Observer(
          warnWhenNoObservables: false,
          builder: (context) => Row(
            textDirection: TextDirection.ltr,
            spacing: fiatCurrency?.signTouchesAmount == true ? 0 : 6,
            children: [
              if (fiatCurrency?.signAfterAmount == false) _sign(context),
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
              if (fiatCurrency?.signAfterAmount == true) _sign(context),
            ],
          ),
        ),
      );

  Widget _sign(BuildContext context) => Text(
        fiatCurrency!.sign,
        style: TextStyle(
          fontSize: 36,
          color: highlight
              ? Theme.of(context).colorScheme.primary.withAlpha(128)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}
