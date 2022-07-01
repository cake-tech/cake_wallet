import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoundedCheckbox extends StatefulWidget {
  RoundedCheckbox({Key key, @required this.value, this.caption = '', @required this.onChanged}) : super(key: key);

  final bool value;
  final String caption;
  final Function(bool) onChanged;

  @override
  RoundedCheckboxState createState() => RoundedCheckboxState(value, caption, onChanged);
}

class RoundedCheckboxState extends State<RoundedCheckbox> {
  RoundedCheckboxState(this.value, this.caption, this.onChanged);

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
      child: value
          ? Container(
              height: 20.0,
              width: 20.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(50.0)),
                color: Theme.of(context).accentTextTheme.body2.color,
              ),
              child: Icon(
                Icons.check,
                color: Theme.of(context).backgroundColor,
                size: 14.0,
              ))
          : Offstage(),
    );
  }
}
