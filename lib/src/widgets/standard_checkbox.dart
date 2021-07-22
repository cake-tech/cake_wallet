import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StandardCheckbox extends StatefulWidget {
  StandardCheckbox({
    Key key,
    @required this.value,
    this.caption = '',
    @required this.onChanged}) : super(key: key);

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

  void changeValue(bool newValue) {
    setState(() => value = newValue);
  }

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
          if (caption.isNotEmpty) Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              caption,
              style: TextStyle(
                  fontSize: 16.0,
                  color: Theme.of(context)
                      .primaryTextTheme
                      .title
                      .color),
            )
          )
        ],
      ),
    );
  }
}