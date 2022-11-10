import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/theme_base.dart';

class RoundedCheckboxWidget extends StatelessWidget {
  RoundedCheckboxWidget(
      {required this.value,
        required this.caption,
        required this.onChanged,
        this.currentTheme});

  final bool value;
  final String caption;
  final Function onChanged;
  final ThemeBase? currentTheme;

  bool get darkTheme =>  currentTheme!.type == ThemeType.dark;

  @override
  Widget build(BuildContext context) {

    final baseGradient = LinearGradient(colors: [
      Colors.red, //Fixme Theme.of(context).primaryTextTheme!.subtitle!.color!,
      Colors.red //Fixme Theme.of(context).primaryTextTheme!.subtitle!.decorationColor!,
    ], begin: Alignment.centerLeft, end: Alignment.centerRight);

    final darkThemeGradient = LinearGradient(colors: [
      Palette.blueCraiola,
      Palette.blueGreyCraiola,
    ], begin: Alignment.topLeft, end: Alignment.bottomRight);

    final gradient = darkTheme ? darkThemeGradient : baseGradient;

    final uncheckedColor = darkTheme
        ? Colors.red //Fixme Theme.of(context).accentTextTheme.subhead.decorationColor
        : Colors.white;

    final borderColor = darkTheme
        ? Colors.red //Fixme Theme.of(context).accentTextTheme.subtitle.backgroundColor
        : Colors.transparent;

    final checkedOuterBoxDecoration =
    BoxDecoration(shape: BoxShape.circle, gradient: gradient);
    final outerBoxDecoration = BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).accentTextTheme.overline!.color!,
        border: Border.all(color: borderColor));

    final checkedInnerBoxDecoration =
    BoxDecoration(shape: BoxShape.circle, color: Colors.white);
    final innerBoxDecoration =
    BoxDecoration(shape: BoxShape.circle, color: uncheckedColor);

    return GestureDetector(
      onTap: () => onChanged(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 24.0,
            width: 24.0,
            child: DecoratedBox(
              decoration:
              value ? checkedOuterBoxDecoration : outerBoxDecoration,
              child: Padding(
                padding: EdgeInsets.all(value ? 4.0 : 1.0),
                child: DecoratedBox(
                  decoration:
                  value ? checkedInnerBoxDecoration : innerBoxDecoration,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              caption,
              style: TextStyle(
                  color: Colors.red, //Fixme Theme.of(context).primaryTextTheme.title.color,
                  fontSize: 18,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none),
            ),
          )
        ],
      ),
    );
  }
}