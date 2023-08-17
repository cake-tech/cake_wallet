import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:flutter/material.dart';

class PrefixCurrencyIcon extends StatelessWidget {
  PrefixCurrencyIcon({
    required this.isSelected,
    required this.title,
    this.onTap,
  });

  final bool isSelected;
  final String title;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 6.0, 8.0, 0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: isSelected
                    ? Theme.of(context)
                        .extension<SendPageTheme>()!
                        .templateSelectedCurrencyBackgroundColor
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (onTap != null)
                    Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Image.asset(
                        'assets/images/arrow_bottom_purple_icon.png',
                        color: Colors.white,
                        height: 8,
                      ),
                    ),
                  Text(
                    title + ':',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context)
                              .extension<SendPageTheme>()!
                              .templateSelectedCurrencyTitleColor
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
