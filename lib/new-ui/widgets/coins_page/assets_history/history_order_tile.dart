import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class HistoryOrderTile extends StatelessWidget {
  const HistoryOrderTile(
      {super.key,
        required this.date,
        required this.amount,
        required this.amountFiat,
        required this.roundedTop,
        required this.roundedBottom,
        required this.bottomSeparator,
      });

  final String date;
  final String amount;
  final String amountFiat;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;




  @override
  Widget build(BuildContext context) {

    return HistoryTileBase(
      title: "Order",
      date: date,
      amount: amount,
      amountFiat: amountFiat,
      leadingIcon:Image.asset("assets/images/cakepay.png"),
      roundedTop: roundedTop,
      roundedBottom: roundedBottom,
      bottomSeparator: bottomSeparator,
    );

  }

}
