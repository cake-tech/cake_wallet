import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class HistoryOrderTile extends StatelessWidget {
  const HistoryOrderTile({
    required this.date,
    required this.amount,
    required this.amountFiat,
    required this.roundedTop,
    required this.roundedBottom,
    required this.bottomSeparator,
    super.key,
  });

  final String date;
  final Money amount;
  final Money amountFiat;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;

  @override
  Widget build(BuildContext context) => HistoryTileBase(
        title: "Order",
        date: date,
        amount: amount,
        amountFiat: amountFiat,
        leadingIcon: Image.asset("assets/images/cakepay.png"),
        roundedTop: roundedTop,
        roundedBottom: roundedBottom,
        bottomSeparator: bottomSeparator,
      );
}
