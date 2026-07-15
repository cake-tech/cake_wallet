import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class HistoryTileBase extends StatelessWidget {
  const HistoryTileBase({
    super.key,
    this.title,
    this.titleWidget,
    required this.date,
    this.amount,
    required this.leadingIcon,
    this.amountFiat,
    required this.roundedTop,
    required this.roundedBottom,
    required this.bottomSeparator,
    this.primaryTextColor,
    this.asset,
    this.amountWidget,
    this.amountFiatWidget,
  })  : assert((title != null || titleWidget != null) && (title == null || titleWidget == null)),
        assert(
            (amountWidget != null || amount != null) && (amountWidget == null || amount == null)),
        assert((amountFiatWidget != null || amountFiat != null) &&
            (amountFiatWidget == null || amountFiat == null));

  final String? title;
  final Widget? titleWidget;
  final String date;
  final String? amount;
  final Widget? amountWidget;
  final String? amountFiat;
  final Widget? amountFiatWidget;
  final Widget leadingIcon;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final Color? primaryTextColor;
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
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.only(
              topLeft: Radius.circular(roundedTop ? 22 : 0),
              topRight: Radius.circular(roundedTop ? 22 : 0),
              bottomLeft: Radius.circular(roundedBottom ? 22 : 0),
              bottomRight: Radius.circular(roundedBottom ? 22 : 0),
            )),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
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
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    height: 36,
                    width: 36,
                    child: leadingIcon,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Text(title!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface))
                            else if (titleWidget != null)
                              titleWidget!,
                            Text(date,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (amount != null)
                              Text(amount!,
                                  style: TextStyle(
                                      color: primaryTextColor ??
                                          Theme.of(context).colorScheme.onSurface))
                            else if (amountWidget != null)
                              amountWidget!,
                            if (amountFiat != null)
                              Text(amountFiat!,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant))
                            else if (amountFiatWidget != null)
                              amountFiatWidget!
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (bottomSeparator)
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
              padding: EdgeInsets.only(left: 56, right: 16),
              child: Container(
                  height: 1, color: Theme.of(context).colorScheme.outlineVariant.withAlpha(175)),
            ),
          )
      ],
    );
  }
}
