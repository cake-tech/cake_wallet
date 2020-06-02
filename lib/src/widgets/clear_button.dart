import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ClearButton extends StatelessWidget {
  ClearButton({@required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {

    return ButtonTheme(
      minWidth: double.minPositive,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: FlatButton(
        padding: EdgeInsets.all(0),
        child: Text(
          S.of(context).clear,
          style: TextStyle(
            color: Theme.of(context).primaryTextTheme.caption.color,
            fontWeight: FontWeight.w500,
            fontSize: 14),
        ),
        onPressed: onPressed),
    );
  }
}