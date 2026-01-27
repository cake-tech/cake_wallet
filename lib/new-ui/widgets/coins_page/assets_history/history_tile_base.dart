import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryTileBase extends StatelessWidget {
  const HistoryTileBase({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.leadingIcon,
    required this.amountFiat,
    required this.roundedTop,
    required this.roundedBottom,
    required this.bottomSeparator,
    this.asset,
  });

  final String title;
  final String date;
  final String amount;
  final String amountFiat;
  final Widget leadingIcon;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final CryptoCurrency? asset;

  // String _getDirectionIcon() {
  //   if (pending) {
  //     return direction == TransactionDirection.incoming
  //         ? 'assets/new-ui/history-receiving.svg'
  //         : 'assets/new-ui/history-sending.svg';
  //   } else {
  //     return direction == TransactionDirection.incoming
  //         ? 'assets/new-ui/history-received.svg'
  //         : 'assets/new-ui/history-sent.svg';
  //   }
  // }
  //
  // Widget _getLeadingIcon(BuildContext context) {
  //   if (asset == CryptoCurrency.btcln) {
  //     return Stack(
  //       children: [
  //         Image.asset(
  //           asset!.iconPath!,
  //           width: 34,
  //           height: 34,
  //         ),
  //         Positioned(
  //           top: 20,
  //           left: 20,
  //           child: SvgPicture.asset(
  //             'assets/new-ui/chain_badges/lightning.svg',
  //             width: 16,
  //             height: 16,
  //           ),
  //         )
  //       ],
  //     );
  //   }
  //
  //   return SvgPicture.asset(_getDirectionIcon());
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(roundedTop ? 12 : 0),
                topRight: Radius.circular(roundedTop ? 12 : 0),
                bottomLeft: Radius.circular(roundedBottom ? 12 : 0),
                bottomRight: Radius.circular(roundedBottom ? 12 : 0),
              )),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    height: 36,
                    width: 36,
                    child: leadingIcon,
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
          padding: EdgeInsets.symmetric(horizontal: 12),
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
