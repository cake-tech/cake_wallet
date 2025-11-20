import 'package:cw_core/transaction_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile(
      {super.key,
      required this.title,
      required this.date,
      required this.amount,
      required this.amountFiat,
      required this.roundedTop,
      required this.roundedBottom,
      required this.direction,
      required this.pending,
      required this.bottomSeparator});

  final String title;
  final String date;
  final String amount;
  final String amountFiat;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final TransactionDirection direction;
  final bool pending;

  String _getDirectionIcon() {
    if (pending) {
      return direction == TransactionDirection.incoming
          ? 'assets/new-ui/history-receiving.svg'
          : 'assets/new-ui/history-sending.svg';
    } else {
      return direction == TransactionDirection.incoming
          ? 'assets/new-ui/history-received.svg'
          : 'assets/new-ui/history-sent.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(roundedTop ? 12.0 : 0.0),
                topRight: Radius.circular(roundedTop ? 12.0 : 0.0),
                bottomLeft: Radius.circular(roundedBottom ? 12.0 : 0.0),
                bottomRight: Radius.circular(roundedBottom ? 12.0 : 0.0),
              )),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: SvgPicture.asset(_getDirectionIcon()),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title),
                          Text(date),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(amount),
                          Text(amountFiat),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: SizedBox(
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
