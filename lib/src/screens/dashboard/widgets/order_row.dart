import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/get_buy_provider_icon.dart';
import 'package:flutter/material.dart';

class OrderRow extends StatelessWidget {
  OrderRow({
    @required this.onTap,
    @required this.provider,
    this.from,
    this.to,
    this.createdAtFormattedDate,
    this.formattedAmount});
  final VoidCallback onTap;
  final BuyProviderDescription provider;
  final String from;
  final String to;
  final String createdAtFormattedDate;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        Theme.of(context).primaryTextTheme.display4.backgroundColor;

    final providerIcon = getBuyProviderIcon(provider, iconColor: iconColor);

    return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (providerIcon != null) Padding(
                padding: EdgeInsets.only(right: 12),
                child: providerIcon,
              ),
              Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('$from → $to',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor
                                )),
                            formattedAmount != null
                                ? Text(formattedAmount + ' ' + to,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor
                                ))
                                : Container()
                          ]),
                      SizedBox(height: 5),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(createdAtFormattedDate,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme
                                        .overline.backgroundColor))
                          ])
                    ],
                  )
              )
            ],
          ),
        ));
  }
}