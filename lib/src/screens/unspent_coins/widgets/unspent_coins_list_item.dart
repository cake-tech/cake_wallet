import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class UnspentCoinsListItem extends StatelessWidget {
  UnspentCoinsListItem({
    @required this.address,
    @required this.amount,
    @required this.isSending,
    @required this.onCheckBoxTap,
  });

  static const amountColor = Palette.darkBlueCraiola;
  static const addressColor = Palette.darkGray;
  static const selectedItemColor = Palette.paleCornflowerBlue;
  static const unselectedItemColor = Palette.moderateLavender;

  final String address;
  final String amount;
  final bool isSending;
  final Function() onCheckBoxTap;

  @override
  Widget build(BuildContext context) {
    final itemColor = isSending? selectedItemColor : unselectedItemColor;

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
                child: GestureDetector(
                  onTap: () => onCheckBoxTap?.call(),
                  child: Container(
                    height: 24.0,
                    width: 24.0,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .color,
                            width: 1.0),
                        borderRadius: BorderRadius.all(
                            Radius.circular(8.0)),
                        color: Theme.of(context).backgroundColor),
                    child: isSending
                      ? Icon(
                        Icons.check,
                        color: Colors.blue,
                        size: 20.0,
                      )
                      : Offstage(),
                  )
                )
            ),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        amount,
                        style: TextStyle(
                            color: amountColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                        ),
                        maxLines: 1,
                      ),
                      AutoSizeText(
                        address,
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