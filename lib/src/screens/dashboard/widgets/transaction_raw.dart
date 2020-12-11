import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/transaction_direction.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TransactionRow extends StatelessWidget {
  TransactionRow(
      {this.direction,
      this.formattedDate,
      this.formattedAmount,
      this.formattedFiatAmount,
      this.isPending,
      @required this.onTap});

  final VoidCallback onTap;
  final TransactionDirection direction;
  final String formattedDate;
  final String formattedAmount;
  final String formattedFiatAmount;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Container(
          height: 62,
          color: Colors.transparent,
          padding: EdgeInsets.only(left: 24, right: 24),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).textTheme.overline.decorationColor
                  ),
                  child: Image.asset(
                      direction == TransactionDirection.incoming
                          ? 'assets/images/down_arrow.png'
                          : 'assets/images/up_arrow.png'),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    height: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  (direction == TransactionDirection.incoming
                                          ? S.of(context).received
                                          : S.of(context).sent) +
                                      (isPending ? S.of(context).pending : ''),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).accentTextTheme.
                                      display3.backgroundColor)),
                              Text(formattedAmount,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).accentTextTheme.
                                      display3.backgroundColor))
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(formattedDate,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .overline
                                          .backgroundColor)),
                              Text(formattedFiatAmount,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .overline
                                          .backgroundColor))
                            ]),
                      ],
                    ),
                  ),
                )
              ]),
        ));
  }
}
