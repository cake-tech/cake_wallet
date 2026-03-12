import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:flutter/material.dart';

class PayjoinHistoryTile extends StatelessWidget {
  const PayjoinHistoryTile(
      {super.key,
      required this.createdAt,
      required this.amount,
      required this.currency,
      required this.state,
      required this.isSending,
      required this.roundedTop,
      required this.roundedBottom,
      required this.bottomSeparator});

  final String createdAt;
  final String amount;
  final String currency;
  final String state;
  final bool isSending;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;

  @override
  Widget build(BuildContext context) {
    return HistoryTileBase(
        title: "${isSending ? S.of(context).outgoing : S.of(context).incoming} Payjoin",
        date: createdAt,
        amount: amount + " " + currency,
        leadingIcon: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            'assets/images/payjoin.png',
            width: 36,
            height: 36,
          ),
        ),
        amountFiat: state,
        roundedTop: roundedTop,
        roundedBottom: roundedBottom,
        bottomSeparator: bottomSeparator);
  }
}
