import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:flutter/material.dart';

class AnonpayHistoryTile extends StatelessWidget {
  const AnonpayHistoryTile(
      {super.key,
      required this.provider,
      required this.createdAt,
      required this.amount,
      required this.currency,
      required this.roundedTop,
      required this.roundedBottom,
      required this.bottomSeparator});

  final String provider;
  final String createdAt;
  final String amount;
  final String currency;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;

  @override
  Widget build(BuildContext context) {
    return HistoryTileBase(
        title: provider,
        date: createdAt,
        amount: amount + " " + currency,
        leadingIcon: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset('assets/images/trocador.png', width: 36, height: 36)),
        amountFiat: "",
        roundedTop: roundedTop,
        roundedBottom: roundedBottom,
        bottomSeparator: bottomSeparator);
  }
}
