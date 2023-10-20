import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';

class UnspentCoinsListItem extends StatelessWidget {
  UnspentCoinsListItem({
    required this.note,
    required this.amount,
    required this.address,
    required this.isSending,
    required this.isFrozen,
    required this.isChange,
    this.onCheckBoxTap,
  });

  final String note;
  final String amount;
  final String address;
  final bool isSending;
  final bool isFrozen;
  final bool isChange;
  final Function()? onCheckBoxTap;

  @override
  Widget build(BuildContext context) {
    final unselectedItemColor = Theme.of(context).cardColor;
    final selectedItemColor = Theme.of(context).primaryColor;
    final itemColor = isSending ? selectedItemColor : unselectedItemColor;

    final amountColor =
        isSending ? Colors.white : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor;
    final addressColor = isSending
        ? Colors.white.withOpacity(0.5)
        : Theme.of(context).extension<CakeTextTheme>()!.buttonSecondaryTextColor;

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
                    iconColor: amountColor,
                    borderColor: addressColor,
                    value: isSending,
                    onChanged: (value) => onCheckBoxTap?.call())),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (note.isNotEmpty)
                          AutoSizeText(
                            note,
                            style: TextStyle(
                                color: amountColor, fontSize: 15, fontWeight: FontWeight.w600),
                            maxLines: 1,
                          ),
                        AutoSizeText(
                          amount,
                          style: TextStyle(
                              color: amountColor, fontSize: 15, fontWeight: FontWeight.w600),
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
                              style: TextStyle(
                                  color: amountColor, fontSize: 7, fontWeight: FontWeight.w600),
                            )),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AutoSizeText(
                          '${address.substring(0, 5)}...${address.substring(address.length - 5)}', // ToDo: Maybe use address label
                          style: TextStyle(
                            color: addressColor,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                        ),
                        if (isChange)
                          Container(
                            height: 17,
                            padding: EdgeInsets.only(left: 6, right: 6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(8.5)),
                                color: Colors.white),
                            alignment: Alignment.center,
                            child: Text(
                              S.of(context).unspent_change,
                              style: TextStyle(
                                color: itemColor,
                                fontSize: 7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ])),
          ],
        ));
  }
}
