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
                Expanded(
                  child: Container(
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
                                      color: Colors.white)),
                              Container(
                                  decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                      color: (direction ==
                                              TransactionDirection.incoming
                                          ? Colors.green.withOpacity(0.8)
                                          : Theme.of(context)
                                              .accentTextTheme
                                              .body2
                                              .decorationColor
                                              .withOpacity(0.8))),
                                  padding: EdgeInsets.only(
                                      top: 3, bottom: 3, left: 10, right: 10),
                                  child: Text(formattedAmount,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white)))
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
