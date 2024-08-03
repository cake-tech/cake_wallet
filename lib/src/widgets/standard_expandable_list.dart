import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

class StandardExpandableList<T> extends StatelessWidget {
  StandardExpandableList({
    required this.title,
    required this.expandableItems,
    this.decoration,
  });

  final String title;
  final List<T> expandableItems;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration ??
          BoxDecoration(
            color: Theme.of(context).colorScheme.background,
          ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
          collapsedIconColor:
              Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
            ),
            textAlign: TextAlign.left,
          ),
          children: expandableItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.toString(),
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
