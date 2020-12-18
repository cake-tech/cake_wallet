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
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              SizedBox(width: 12),
              Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            Text(formattedAmount,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white))
                          ]),
                      SizedBox(height: 5),
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
                          ])
                    ],
                  )
              )
            ],
          ),
        ));
  }
}
