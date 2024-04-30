import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';

class SelectButton extends StatelessWidget {
  SelectButton({
    required this.text,
    required this.onTap,
    this.image,
    this.isSelected = false,
    this.showTrailingIcon = true,
    this.height = 60,
    this.textSize = 18,
    this.color,
    this.textColor,
    this.arrowColor,
    this.borderColor,
  });

  final Image? image;
  final String text;
  final double textSize;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showTrailingIcon;
  final double height;
  final Color? color;
  final Color? textColor;
  final Color? arrowColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? (isSelected ? Colors.green : Theme.of(context).cardColor);
    final effectiveTextColor = textColor ?? (isSelected
        ? Theme.of(context).extension<WalletListTheme>()!.restoreWalletButtonTextColor
        : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor);
    final effectiveArrowColor = arrowColor ?? (isSelected
        ? Theme.of(context).extension<WalletListTheme>()!.restoreWalletButtonTextColor
        : Theme.of(context).extension<FilterTheme>()!.titlesColor);

    final selectArrowImage = Image.asset('assets/images/select_arrow.png',
        color: effectiveArrowColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        padding: EdgeInsets.only(left: 30, right: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          color: backgroundColor,
          border: borderColor != null ? Border.all(color: borderColor!) : null,

        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                image ?? Offstage(),
                Padding(
                  padding: image != null
                    ? EdgeInsets.only(left: 15)
                    : EdgeInsets.only(left: 0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.w500,
                      color: effectiveTextColor,
                    ),
                  ),
                )
              ],
            ),
            if (showTrailingIcon) selectArrowImage
          ],
        ),
      ),
    );
  }
}
