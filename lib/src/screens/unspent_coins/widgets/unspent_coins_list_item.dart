import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

class UnspentCoinsListItem extends StatelessWidget {
  UnspentCoinsListItem({
    required this.note,
    required this.amount,
    required this.address,
    required this.isSending,
    required this.isFrozen,
    this.onCheckBoxTap,
  });

  static const amountColor = Palette.darkBlueCraiola;
  static const addressColor = Palette.darkGray;
  static const selectedItemColor = Palette.paleCornflowerBlue;
  static const unselectedItemColor = Palette.moderateLavender;

  final String note;
  final String amount;
  final String address;
  final bool isSending;
  final bool isFrozen;
  final Function()? onCheckBoxTap;

  @override
  Widget build(BuildContext context) {
    final itemColor = isSending ? selectedItemColor : unselectedItemColor;
    return Container(
        height: 70,
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration:
            BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)), color: itemColor),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
                padding: EdgeInsets.only(right: 12),
                child: StandardCheckbox(
                    value: isSending, onChanged: (value) => onCheckBoxTap?.call())),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        if (note.isNotEmpty)
                          AutoSizeText(
                            note,
                            style: TextStyle(
                                color: amountColor, fontSize: 15, fontWeight: FontWeight.w600),
                            maxLines: 1,
                          ),
                        AutoSizeText(
                          amount,
                          style:
                              TextStyle(color: amountColor, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                        )
                      ]),
                      if (isFrozen)
                        Container(
                            height: 17,
                            padding: EdgeInsets.only(left: 6, right: 6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(8.5)),
                                color: Colors.white),
                            alignment: Alignment.center,
                            child: Text(
                              S.of(context).frozen,
                              style:
                              TextStyle(color: amountColor, fontSize: 7, fontWeight: FontWeight.w600),
                            ))
                    ],
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          address,
                          style: TextStyle(
                            color: addressColor,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ])),
          ],
        ));
  }
}
