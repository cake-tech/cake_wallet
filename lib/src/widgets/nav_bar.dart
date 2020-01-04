import 'package:cake_wallet/theme_changer.dart';
import 'package:cake_wallet/themes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  static const _originalHeight = 44.0; // iOS nav bar height
  static const _height = 60.0;

  factory NavBar.withShadow(
      {BuildContext context,
      Widget leading,
      Widget middle,
      Widget trailing,
      Color backgroundColor}) {
    final _themeChanger = Provider.of<ThemeChanger>(context);
    final _isDarkTheme = _themeChanger.getTheme() == Themes.darkTheme;

    return NavBar._internal(
      leading: leading,
      middle: middle,
      trailing: trailing,
      height: 80,
      backgroundColor:
          _isDarkTheme ? Theme.of(context).backgroundColor : backgroundColor,
      decoration: BoxDecoration(
          color: _isDarkTheme
              ? Theme.of(context).backgroundColor
              : backgroundColor,
          boxShadow: [
            BoxShadow(
                color: Color.fromRGBO(132, 141, 198, 0.11),
                blurRadius: 8,
                offset: Offset(0, 2))
          ]),
    );
  }

  factory NavBar(
      {BuildContext context,
      Widget leading,
      Widget middle,
      Widget trailing,
      Color backgroundColor}) {
    final _themeChanger = Provider.of<ThemeChanger>(context);
    final _isDarkTheme = _themeChanger.getTheme() == Themes.darkTheme;

    return NavBar._internal(
        leading: leading,
        middle: middle,
        trailing: trailing,
        height: _height,
        backgroundColor:
            _isDarkTheme ? Theme.of(context).backgroundColor : backgroundColor);
  }

  final Widget leading;
  final Widget middle;
  final Widget trailing;
  final Color backgroundColor;
  final BoxDecoration decoration;
  final double height;

  NavBar._internal(
      {this.leading,
      this.middle,
      this.trailing,
      this.backgroundColor,
      this.decoration,
      this.height = _height});

  @override
  Widget build(BuildContext context) {
    final pad = height - _originalHeight;
    final paddingTop = pad / 2;
    final _paddingBottom = (pad / 2);

    return Container(
      decoration: decoration ?? BoxDecoration(color: backgroundColor),
      padding:
          EdgeInsetsDirectional.only(bottom: _paddingBottom, top: paddingTop),
      child: CupertinoNavigationBar(
        leading: leading,
        middle: middle,
        trailing: trailing,
        backgroundColor: backgroundColor,
        border: null,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return false;
  }
}
