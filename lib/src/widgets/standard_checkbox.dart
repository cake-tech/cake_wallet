import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StandardCheckbox extends StatefulWidget {
  StandardCheckbox({
    Key? key,
    required this.value,
    this.caption = '',
    this.gradientBackground = false,
    this.borderColor,
    this.iconColor,
    required this.onChanged})
    : super(key: key);

  final bool value;
  final String caption;
  final bool gradientBackground;
  final Color? borderColor;
  final Color? iconColor;
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

    final baseGradient = LinearGradient(colors: [
      Theme.of(context).primaryTextTheme.subtitle1!.color!,
      Theme.of(context).primaryTextTheme.subtitle1!.decorationColor!,
    ], begin: Alignment.centerLeft, end: Alignment.centerRight);

    final boxBorder = Border.all(
        color: widget.borderColor ?? Theme.of(context)
            .primaryTextTheme
            .caption!
            .color!,
        width: 1.0);


    final checkedBoxDecoration = BoxDecoration(
        gradient: widget.gradientBackground ? baseGradient : null,
        border: widget.gradientBackground ? null : boxBorder,
        borderRadius: BorderRadius.all(
            Radius.circular(8.0)));

    final uncheckedBoxDecoration = BoxDecoration(
        border: boxBorder,
        borderRadius: BorderRadius.all(
            Radius.circular(8.0)));

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
            decoration: value ? checkedBoxDecoration : uncheckedBoxDecoration,
            child: value
              ? Icon(
                Icons.check,
                color: widget.iconColor ?? Colors.blue,
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
                      .primaryTextTheme!
                      .headline6!
                      .color!),
            )
          )
        ],
      ),
    );
  }
}