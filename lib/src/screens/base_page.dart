import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/themes.dart';
import 'package:cake_wallet/theme_changer.dart';
import 'package:cake_wallet/palette.dart';

enum AppBarStyle { regular, withShadow, transparent }

abstract class BasePage extends StatelessWidget {
  String get title => null;

  bool get isModalBackButton => false;

  Color get backgroundLightColor => Colors.white;

  Color get backgroundDarkColor => PaletteDark.backgroundColor;

  Color get titleColor => null;

  bool get resizeToAvoidBottomPadding => true;

  bool get extendBodyBehindAppBar => false;

  Widget get endDrawer => null;

  AppBarStyle get appBarStyle => AppBarStyle.regular;

  Widget Function(BuildContext, Widget) get rootWrapper => null;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _closeButtonImage = Image.asset('assets/images/close_button.png');
  final _closeButtonImageDarkTheme =
      Image.asset('assets/images/close_button_dark_theme.png');

  void onOpenEndDrawer() => _scaffoldKey.currentState.openEndDrawer();

  void onClose(BuildContext context) => Navigator.of(context).pop();

  Widget leading(BuildContext context) {
    if (ModalRoute.of(context).isFirst) {
      return null;
    }

    final _backButton = Image.asset('assets/images/back_arrow.png',
          color: titleColor ?? Theme.of(context).primaryTextTheme.title.color);

    final _themeChanger = Provider.of<ThemeChanger>(context);
    final _closeButton = _themeChanger.getTheme() == Themes.darkTheme
    ? _closeButtonImageDarkTheme
    : _closeButtonImage;

    return SizedBox(
      height: 37,
      width: isModalBackButton ? 37 : 20,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            padding: EdgeInsets.all(0),
            onPressed: () => onClose(context),
            child: isModalBackButton ? _closeButton : _backButton),
      ),
    );
  }

  Widget middle(BuildContext context) {
    return title == null
        ? null
        : Text(
            title,
            style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: titleColor ??
                       Theme.of(context).primaryTextTheme.title.color),
          );
  }

  Widget trailing(BuildContext context) => null;

  Widget floatingActionButton(BuildContext context) => null;

  ObstructingPreferredSizeWidget appBar(BuildContext context) {
    final _themeChanger = Provider.of<ThemeChanger>(context);
    final _isDarkTheme = _themeChanger.getTheme() == Themes.darkTheme;
    final appBarColor = _isDarkTheme
                        ? backgroundDarkColor : backgroundLightColor;

    switch (appBarStyle) {
      case AppBarStyle.regular:
        return NavBar(
            context: context,
            leading: leading(context),
            middle: middle(context),
            trailing: trailing(context),
            backgroundColor: appBarColor);

      case AppBarStyle.withShadow:
        return NavBar.withShadow(
            context: context,
            leading: leading(context),
            middle: middle(context),
            trailing: trailing(context),
            backgroundColor: appBarColor);

      case AppBarStyle.transparent:
        return CupertinoNavigationBar(
          leading: leading(context),
          middle: middle(context),
          trailing: trailing(context),
          backgroundColor: Colors.transparent,
          border: null,
        );

      default:
        return NavBar(
            context: context,
            leading: leading(context),
            middle: middle(context),
            trailing: trailing(context),
            backgroundColor: appBarColor);
    }
  }

  Widget body(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final _themeChanger = Provider.of<ThemeChanger>(context);
    final _isDarkTheme = _themeChanger.getTheme() == Themes.darkTheme;

    final root = Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            _isDarkTheme ? backgroundDarkColor : backgroundLightColor,
        resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        endDrawer: endDrawer,
        appBar: appBar(context),
        body: body(context), //SafeArea(child: ),
        floatingActionButton: floatingActionButton(context));

    return rootWrapper?.call(context, root) ?? root;
  }
}
