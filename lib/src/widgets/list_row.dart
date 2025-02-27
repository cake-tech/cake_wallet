import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class ListRow extends StatelessWidget {
  ListRow({
    required this.title,
    required this.value,
    this.titleFontSize = 14,
    this.valueFontSize = 16,
    this.image,
    this.padding,
    this.color,
    this.hintTextColor,
    this.mainTextColor
  });

  final String title;
  final String value;
  final double titleFontSize;
  final double valueFontSize;
  final Image? image;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? hintTextColor;
  final Color? mainTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color ?? Theme.of(context).colorScheme.background,
      child: Padding(
        padding: padding ?? const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: hintTextColor ?? Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor),
                  textAlign: TextAlign.left),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(value,
                          style: TextStyle(
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.w500,
                              color: mainTextColor ?? Theme.of(context).extension<CakeTextTheme>()!.titleColor)),
                    ),
                    image != null
                    ? Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: image,
                    )
                    : Offstage()
                  ],
                ),
              )
            ]),
      ),
    );
  }
}
