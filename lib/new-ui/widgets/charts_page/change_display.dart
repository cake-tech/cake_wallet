import 'package:cake_wallet/di.dart';
import "package:cake_wallet/entities/fiat_currency.dart";
import 'package:cake_wallet/new-ui/model/charts/util/price_change_data.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/change_pill.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:flutter/material.dart';
import "package:flutter_mobx/flutter_mobx.dart";

class ChangeDisplay extends StatelessWidget {
  const ChangeDisplay({super.key, required this.changeData, required this.fiatCurrency});

  final FiatCurrency? fiatCurrency;
  final PriceChangeData changeData;

  String get _change {
    final amount = changeData.amount
        .toStringWithPrecision(fractionalDigits: 2, meaningfulDecimals: 2)
        .withLocalSeperator(getIt.get<AppStore>().settingsStore.languageCode);
    final signedAmount = "${changeData.direction.symbol}$amount";

    return fiatCurrency?.format(signedAmount) ?? signedAmount;
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Observer(
            builder: (context) => Text(
              _change,
              style: TextStyle(fontSize: 16, color: changeData.direction.colorOf(context)),
            ),
          ),
          ChangePill(changePercentage: changeData.percentage, direction: changeData.direction)
        ],
      );
}
