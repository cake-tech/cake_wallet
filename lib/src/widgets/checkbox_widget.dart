import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CheckboxWidget extends StatefulWidget {
  CheckboxWidget({
    @required this.value,
    @required this.caption,
    @required this.onChanged});

  final bool value;
  final String caption;
  final Function(bool) onChanged;

  @override
  CheckboxWidgetState createState() => CheckboxWidgetState(value, caption, onChanged);
}

class CheckboxWidgetState extends State<CheckboxWidget> {
  CheckboxWidgetState(this.value, this.caption, this.onChanged);

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
            height: 16,
            width: 16,
            decoration: BoxDecoration(
                color: value
                    ? Palette.blueCraiola
                    : Theme.of(context).accentTextTheme.subhead.decorationColor,
                borderRadius: BorderRadius.all(Radius.circular(2)),
                border: Border.all(
                    color: value
                        ? Palette.blueCraiola
                        : Theme.of(context).accentTextTheme.overline.color,
                    width: 1
                )
            ),
            child: value
                ? Center(
              child: Icon(
                Icons.done,
                color: Colors.white,
                size: 14,
              ),
            )
                : Offstage(),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              caption,
              style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.title.color,
                  fontSize: 18,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none
              ),
            ),
          )
        ],
      ),
    );
  }
}