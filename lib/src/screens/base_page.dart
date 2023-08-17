import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/src/widgets/nav_bar.dart';
import 'package:cake_wallet/generated/i18n.dart';

enum AppBarStyle { regular, withShadow, transparent }

abstract class BasePage extends StatelessWidget {
  BasePage() : _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldKey;

  final Image closeButtonImage = Image.asset('assets/images/close_button.png');
  final Image closeButtonImageDarkTheme =
      Image.asset('assets/images/close_button_dark_theme.png');

  String? get title => null;

  Color? get backgroundLightColor => null;

  Color? get backgroundDarkColor => null;

  bool get gradientBackground => false;

  bool get gradientAll => false;

  bool get resizeToAvoidBottomInset => true;

  bool get extendBodyBehindAppBar => false;

  Widget? get endDrawer => null;

  AppBarStyle get appBarStyle => AppBarStyle.regular;

  Widget Function(BuildContext, Widget)? get rootWrapper => null;

  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  void onOpenEndDrawer() => _scaffoldKey.currentState!.openEndDrawer();

  void onClose(BuildContext context) => Navigator.of(context).pop();

  Color pageBackgroundColor(BuildContext context) =>
      (currentTheme.type == ThemeType.dark
          ? backgroundDarkColor
          : backgroundLightColor) ??
      (gradientBackground && currentTheme.type == ThemeType.bright
          ? Colors.transparent
          : Theme.of(context).colorScheme.background);

  Color titleColor(BuildContext context) =>
      (gradientBackground && currentTheme.type == ThemeType.bright) ||
              (gradientAll && currentTheme.brightness == Brightness.light)
          ? Colors.white
          : Theme.of(context).appBarTheme.titleTextStyle!.color!;

  Color? pageIconColor(BuildContext context) => titleColor(context);

  Widget closeButton(BuildContext context) => Image.asset(
        currentTheme.type == ThemeType.dark
            ? 'assets/images/close_button_dark_theme.png'
            : 'assets/images/close_button.png',
        color: pageIconColor(context),
        height: 16,
      );

  Widget backButton(BuildContext context) => Icon(
        Icons.arrow_back_ios,
        color: pageIconColor(context),
        size: 16,
      );

  Widget? leading(BuildContext context) {
    if (ModalRoute.of(context)?.isFirst ?? true) {
      return null;
    }

    return MergeSemantics(
      child: SizedBox(
        height: 37,
        width: 37,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: S.of(context).seed_alert_back,
            child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateColor.resolveWith(
                    (states) => Colors.transparent),
              ),
              onPressed: () => onClose(context),
              child: backButton(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget? middle(BuildContext context) {
    return title == null
        ? null
        : Text(
            title!,
            style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
                color: titleColor(context)),
          );
  }

  Widget? trailing(BuildContext context) => null;

  Widget? floatingActionButton(BuildContext context) => null;

  ObstructingPreferredSizeWidget appBar(BuildContext context) {
    final appBarColor = pageBackgroundColor(context);

    switch (appBarStyle) {
      case AppBarStyle.regular:
        // FIX-ME: NavBar no context
        return NavBar(
            // context: context,
            leading: leading(context),
            middle: middle(context),
            trailing: trailing(context),
            backgroundColor: appBarColor);

      case AppBarStyle.withShadow:
        // FIX-ME: NavBar no context
        return NavBar.withShadow(
            // context: context,
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
        // FIX-ME: NavBar no context
        return NavBar(
            // context: context,
            leading: leading(context),
            middle: middle(context),
            trailing: trailing(context),
            backgroundColor: appBarColor);
    }
  }

  Widget body(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final root = Scaffold(
        key: _scaffoldKey,
        backgroundColor: pageBackgroundColor(context),
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        endDrawer: endDrawer,
        appBar: appBar(context),
        body: body(context),
        floatingActionButton: floatingActionButton(context));

    return rootWrapper?.call(context, root) ?? root;
  }
}
