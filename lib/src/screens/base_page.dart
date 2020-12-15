import 'package:cake_wallet/src/themes/theme_base.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/src/widgets/nav_bar.dart';

enum AppBarStyle { regular, withShadow, transparent }

abstract class BasePage extends StatelessWidget {
  BasePage()
      : _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldKey;

  final Image closeButtonImage =
    Image.asset('assets/images/close_button.png');
  final Image closeButtonImageDarkTheme =
    Image.asset('assets/images/close_button_dark_theme.png');

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

  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  void onOpenEndDrawer() => _scaffoldKey.currentState.openEndDrawer();

  void onClose(BuildContext context) => Navigator.of(context).pop();

  Widget leading(BuildContext context) {
    if (ModalRoute.of(context).isFirst) {
      return null;
    }

    final _backButton = Icon(Icons.arrow_back_ios,
      color: titleColor ?? Theme.of(context).primaryTextTheme.title.color,
      size: 16,);
    final _closeButton = currentTheme.type == ThemeType.dark
        ? closeButtonImageDarkTheme : closeButtonImage;

    return SizedBox(
      height: 37,
      width: 37,
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
                fontFamily: 'Lato',
                color: titleColor ??
                    Theme.of(context).primaryTextTheme.title.color),
          );
  }

  Widget trailing(BuildContext context) => null;

  Widget floatingActionButton(BuildContext context) => null;

  ObstructingPreferredSizeWidget appBar(BuildContext context) {
    final appBarColor = currentTheme.type == ThemeType.dark
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
    final _backgroundColor = currentTheme.type == ThemeType.dark
        ? backgroundDarkColor : backgroundLightColor;

    final root = Scaffold(
        key: _scaffoldKey,
        backgroundColor: _backgroundColor,
        resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        endDrawer: endDrawer,
        appBar: appBar(context),
        body: body(context),
        floatingActionButton: floatingActionButton(context));

    return rootWrapper?.call(context, root) ?? root;
  }
}
