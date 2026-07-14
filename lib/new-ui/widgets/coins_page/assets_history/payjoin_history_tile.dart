import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:flutter/material.dart';

class PayjoinHistoryTile extends StatelessWidget {
  const PayjoinHistoryTile({
    super.key,
    required this.createdAt,
    required this.amount,
    required this.state,
    required this.direction,
    required this.pending,
    required this.roundedTop,
    required this.roundedBottom,
    required this.bottomSeparator,
  });

  final String createdAt;
  final String amount;
  final String state;
  final TransactionDirection direction;
  final bool pending;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;

  String _getDirectionIcon() {
    if (pending) {
      return direction == TransactionDirection.incoming
          ? 'assets/new-ui/history-receiving.svg'
          : 'assets/new-ui/history-sending.svg';
    }
    return direction == TransactionDirection.incoming
        ? 'assets/new-ui/history-received.svg'
        : 'assets/new-ui/history-sent.svg';
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final badgeColor = direction == TransactionDirection.outgoing
        ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
        : Colors.green;
    return Stack(
      children: [
        CakeImageWidget(
          imageUrl: 'assets/new-ui/payjoin.svg',
          width: 34,
          height: 34,
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onInverseSurface,
                shape: BoxShape.circle),
            child: CakeImageWidget(
              imageUrl: _getDirectionIcon(),
              height: 14,
              width: 14,
              colorFilter: ColorFilter.mode(badgeColor, BlendMode.srcIn),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoing = direction == TransactionDirection.outgoing;
    return HistoryTileBase(
      title:
          "${isOutgoing ? S.of(context).outgoing : S.of(context).incoming} Payjoin",
      date: createdAt,
      amount: amount,
      leadingIcon: _buildLeadingIcon(context),
      primaryTextColor: isOutgoing
          ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
          : Theme.of(context).colorScheme.onSurface,
      amountFiat: state,
      roundedTop: roundedTop,
      roundedBottom: roundedBottom,
      bottomSeparator: bottomSeparator,
    );
  }
}
