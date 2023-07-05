import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class StandardListStatusRow extends StatelessWidget {
  StandardListStatusRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.background,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor),
                  textAlign: TextAlign.left),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AddressTheme>()!.actionButtonColor,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SyncIndicatorIcon(
                          boolMode: false,
                          value: value,
                          size: 6,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(value,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor))
                      ],
                    ),
                  ),
                ),
              )
            ]),
      ),
    );
  }
}
