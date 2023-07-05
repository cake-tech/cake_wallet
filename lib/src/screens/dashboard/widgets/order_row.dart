import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/buy/get_buy_provider_icon.dart';
import 'package:cake_wallet/themes/extensions/order_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

class OrderRow extends StatelessWidget {
  OrderRow({
    required this.provider,
    required this.from,
    required this.to,
    required this.createdAtFormattedDate,
    this.onTap,
    this.formattedAmount});
  final VoidCallback? onTap;
  final BuyProviderDescription provider;
  final String from;
  final String to;
  final String createdAtFormattedDate;
  final String? formattedAmount;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        Theme.of(context).extension<OrderTheme>()!.iconColor;

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
                                    color: Theme.of(context).extension<DashboardPageTheme>()!.textColor
                                )),
                            formattedAmount != null
                                ? Text(formattedAmount! + ' ' + to,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).extension<DashboardPageTheme>()!.textColor
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
                                    color: Theme.of(context).extension<CakeTextTheme>()!.dateSectionRowColor))
                          ])
                    ],
                  )
              )
            ],
          ),
        ));
  }
}