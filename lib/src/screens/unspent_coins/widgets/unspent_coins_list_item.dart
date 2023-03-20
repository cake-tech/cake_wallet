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
    final itemColor = isSending? selectedItemColor : unselectedItemColor;
    final _note = (note?.isNotEmpty ?? false) ? note : address;

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
                    value: isSending, onChanged: (value) => onCheckBoxTap?.call())
            ),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              amount,
                              style: TextStyle(
                                  color: amountColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (isFrozen) Container(
                            height: 17,
                            padding: EdgeInsets.only(left: 6, right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(8.5)),
                              color: Colors.white),
                            alignment: Alignment.center,
                            child: Text(
                                S.of(context).frozen,
                                style: TextStyle(
                                  color: amountColor,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600
                                ),
                            )
                          )
                        ],
                      ),
                      Text(
                        _note,
                        style: TextStyle(
                          color: addressColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis
                      )
                    ]
                )
            )
          ],
        )
    );
  }
}