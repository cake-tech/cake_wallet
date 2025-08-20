import 'dart:io';

import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/utils/route_aware.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/widgets/nav_bar.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

enum AppBarStyle { regular, withShadow, transparent, completelyTransparent }

abstract class BasePage extends StatelessWidget {
  BasePage() : _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldKey;

  final Image closeButtonImage = Image.asset('assets/images/close_button.png');
  final Image closeButtonImageDarkTheme = Image.asset('assets/images/close_button_dark_theme.png');

  String? get title => null;

  Color? get backgroundLightColor => null;

  Color? get backgroundDarkColor => null;

  bool get gradientBackground => false;

  bool get gradientAll => false;

  bool get resizeToAvoidBottomInset => true;

  bool get extendBodyBehindAppBar => false;

  Widget? get endDrawer => null;

  Function(BuildContext context)? get pushToWidget => null;

  Function(BuildContext context)? get pushToNextWidget => null;

  Function(BuildContext context)? get popWidget => null;

  Function(BuildContext context)? get popNextWidget => null;

  AppBarStyle get appBarStyle => AppBarStyle.regular;

  Widget Function(BuildContext, Widget)? get rootWrapper => null;

  MaterialThemeBase get currentTheme => getIt.get<ThemeStore>().currentTheme;

  void onOpenEndDrawer() => _scaffoldKey.currentState!.openEndDrawer();

  void onClose(BuildContext context) => Navigator.of(context).pop();

  Color pageBackgroundColor(BuildContext context) =>
      (currentTheme.isDark ? backgroundDarkColor : backgroundLightColor) ??
      (gradientBackground ? Colors.transparent : Theme.of(context).colorScheme.surface);

  Color titleColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  Color? pageIconColor(BuildContext context) => titleColor(context);

  Widget closeButton(BuildContext context) => Image.asset(
        currentTheme.isDark
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
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent),
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 18.0,
                  color: titleColor(context),
                ),
          );
  }

  Widget? trailing(BuildContext context) => null;

  Widget? floatingActionButton(BuildContext context) => null;

  PreferredSizeWidget appBar(BuildContext context) {
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

      case AppBarStyle.completelyTransparent:
        return AppBar(
          leading: leading(context),
          title: middle(context),
          actions: <Widget>[if (trailing(context) != null) trailing(context)!],
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
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
    final root = RouteAwareWidget(
      child: Observer(
        builder: (context) {
          final backgroundImage = getIt.get<SettingsStore>().backgroundImage;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: backgroundImage.isNotEmpty
                  ? DecorationImage(
                      image: FileImage(File(backgroundImage)),
                      fit: BoxFit.cover,
                    )
                  : null,
              // color: Colors.grey[200],
            ),
            child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: pageBackgroundColor(context),
                resizeToAvoidBottomInset: resizeToAvoidBottomInset,
                extendBodyBehindAppBar: extendBodyBehindAppBar,
                endDrawer: endDrawer,
                appBar: appBar(context),
                body: body(context),
                floatingActionButton: floatingActionButton(context)),
          );
        }
      ),
      pushToWidget: (context) => pushToWidget?.call(context),
      pushToNextWidget: (context) => pushToNextWidget?.call(context),
      popWidget: (context) => popWidget?.call(context),
      popNextWidget: (context) => popNextWidget?.call(context),
    );

    return rootWrapper?.call(context, root) ?? root;
  }
}
