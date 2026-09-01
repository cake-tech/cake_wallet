import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class PayjoinHistoryTile extends StatelessWidget {
  const PayjoinHistoryTile({
    required this.createdAt,
    required this.amount,
    required this.currency,
    required this.state,
    required this.isSending,
    required this.roundedTop,
    required this.roundedBottom,
    required this.bottomSeparator,
    super.key,
  });

  final String createdAt;
  final Money amount;
  final String currency;
  final String state;
  final bool isSending;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;

  @override
  Widget build(BuildContext context) => HistoryTileBase(
        title: "${isSending ? S.of(context).outgoing : S.of(context).incoming} Payjoin - ${state}",
        date: createdAt,
        amount: amount,
        leadingIcon: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            "assets/images/payjoin.png",
            width: 36,
            height: 36,
          ),
        ),
        roundedTop: roundedTop,
        roundedBottom: roundedBottom,
        bottomSeparator: bottomSeparator,
      );
}
