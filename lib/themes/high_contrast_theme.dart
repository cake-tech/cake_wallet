import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/indicator_dot_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/monero_light_theme.dart';
import 'package:flutter/material.dart';

class HighContrastTheme extends MoneroLightTheme {
  HighContrastTheme({required int raw}) : super(raw: raw) {
    colorScheme = ColorScheme.fromSwatch(
        primarySwatch: Colors.grey,
        accentColor: primaryColor,
        backgroundColor: Colors.white,
        cardColor: containerColor,
        brightness: Brightness.light);
  }

  @override
  String get title => S.current.high_contrast_theme;
  @override
  Color get primaryColor => Colors.black;
  @override
  Color get containerColor => Palette.highContrastGray;

  @override
  Color get primaryTextColor => colorScheme.onBackground;

  @override
  SyncIndicatorTheme get syncIndicatorStyle =>
      super.syncIndicatorStyle.copyWith(
          textColor: colorScheme.background,
          syncedBackgroundColor: containerColor);

  @override
  BalancePageTheme get balancePageTheme => super.balancePageTheme.copyWith(
      textColor: Colors.white,
      labelTextColor: Colors.grey,
      assetTitleColor: Colors.white,
      balanceAmountColor: Colors.white);

  @override
  DashboardPageTheme get dashboardPageTheme =>
      super.dashboardPageTheme.copyWith(
          // textColor: Colors.white,
          mainActionsIconColor: Colors.white,
          indicatorDotTheme: IndicatorDotTheme(
              indicatorColor:
                  super.dashboardPageTheme.indicatorDotTheme.indicatorColor,
              activeIndicatorColor: primaryColor));
}
