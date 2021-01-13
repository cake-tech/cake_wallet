import 'package:flutter/material.dart';

class TrailButton extends StatelessWidget {
  TrailButton({
    @required this.caption,
    @required this.onPressed
  });

  final String caption;
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
          caption,
          style: TextStyle(
            color: Theme.of(context).textTheme.display1.color,
            fontWeight: FontWeight.w500,
            fontSize: 14),
        ),
        onPressed: onPressed),
    );
  }
}