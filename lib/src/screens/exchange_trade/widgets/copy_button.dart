import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CopyButton extends StatelessWidget {

  final VoidCallback onPressed;
  final Color color;
  final Color borderColor;
  final String text;

  const CopyButton({
    @required this.onPressed,
    @required this.text,
    @required this.color,
    @required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: double.infinity,
      height: 44.0,
      child: FlatButton(
        onPressed: onPressed,
        color: color,
        shape: RoundedRectangleBorder(side: BorderSide(color: borderColor), borderRadius: BorderRadius.circular(10.0)),
        child: Text(text, style: TextStyle(fontSize: 14.0)),
      )
    );
  }
}