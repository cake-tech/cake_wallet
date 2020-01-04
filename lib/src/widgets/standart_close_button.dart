import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class StandartCloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      width: 37,
      child: FlatButton(
          padding: EdgeInsets.all(0),
          onPressed: () => Navigator.of(context).pop(),
          child: Image.asset('assets/images/close_button.png')),
    );
  }
}