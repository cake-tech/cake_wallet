import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class TrailButton extends StatelessWidget {
  TrailButton({
    required this.caption,
    required this.onPressed,
    this.textColor});

  final String caption;
  final VoidCallback onPressed;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: double.minPositive,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: TextButton(
          // FIX-ME: ignored padding
          //padding: EdgeInsets.all(0),
          child: Text(
            caption,
            style: TextStyle(
                color: textColor ??
                    Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
          onPressed: onPressed),
    );
  }
}
