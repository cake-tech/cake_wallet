import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class UnspentCoinsListItem extends StatefulWidget {
  UnspentCoinsListItem({
    @required this.address,
    @required this.amount,
    @required this.isSending,
    @required this.onCheckBoxTap,
  });

  final String address;
  final String amount;
  final bool isSending;
  final Function(bool) onCheckBoxTap;

  @override UnspentCoinsListItemState createState() =>
      UnspentCoinsListItemState(
        address: address,
        amount: amount,
        isSending: isSending,
        onCheckBoxTap: onCheckBoxTap
      );

}

class UnspentCoinsListItemState extends State<UnspentCoinsListItem> {
  UnspentCoinsListItemState({
    @required this.address,
    @required this.amount,
    @required this.isSending,
    @required this.onCheckBoxTap,
  }) : checkBoxValue = isSending;

  static const amountColor = Palette.darkBlueCraiola;
  static const addressColor = Palette.darkGray;
  static const selectedItemColor = Palette.paleCornflowerBlue;
  static const unselectedItemColor = Palette.moderateLavender;

  final String address;
  final String amount;
  final bool isSending;
  final Function(bool) onCheckBoxTap;

  bool checkBoxValue;

  @override
  Widget build(BuildContext context) {
    final itemColor = checkBoxValue? selectedItemColor : unselectedItemColor;

    return Container(
      height: 62,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: itemColor),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: EdgeInsets.only(right: 12),
              child: StandardCheckbox(
                  value: checkBoxValue,
                  onChanged: (value) {
                    onCheckBoxTap(value);
                    checkBoxValue = value;
                    setState(() {});
                  }
              )
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  amount ?? 'Amount',
                  style: TextStyle(
                      color: amountColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                  ),
                  maxLines: 1,
                ),
                AutoSizeText(
                  address ?? 'Address',
                  style: TextStyle(
                    color: addressColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                )
              ]
            )
          )
        ],
      )
    );
  }
}