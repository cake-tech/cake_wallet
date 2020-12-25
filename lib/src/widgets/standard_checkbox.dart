import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StandardCheckbox extends StatefulWidget {
  StandardCheckbox({
    @required this.value,
    this.caption = '',
    @required this.onChanged});

  final bool value;
  final String caption;
  final Function(bool) onChanged;

  @override
  StandardCheckboxState createState() =>
      StandardCheckboxState(value, caption, onChanged);
}

class StandardCheckboxState extends State<StandardCheckbox> {
  StandardCheckboxState(this.value, this.caption, this.onChanged);

  bool value;
  String caption;
  Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        value = !value;
        onChanged(value);
        setState(() {});
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 24.0,
            width: 24.0,
            margin: EdgeInsets.only(
              right: 10.0,
            ),
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
            child: value
              ? Icon(
                Icons.check,
                color: Colors.blue,
                size: 20.0,
              )
              : Offstage(),
          ),
          Text(
            caption,
            style: TextStyle(
                fontSize: 16.0,
                color: Theme.of(context)
                    .primaryTextTheme
                    .title
                    .color),
          )
        ],
      ),
    );
  }
}