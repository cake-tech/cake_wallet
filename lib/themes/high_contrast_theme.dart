import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/extensions/account_list_theme.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/indicator_dot_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
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
  Color get dialogBackgroundColor => Colors.white;

  @override
  CakeTextTheme get cakeTextTheme => super.cakeTextTheme.copyWith(
      buttonTextColor: Colors.white, buttonSecondaryTextColor: Colors.white.withOpacity(0.5));

  @override
  SyncIndicatorTheme get syncIndicatorStyle => super
      .syncIndicatorStyle
      .copyWith(textColor: colorScheme.background, syncedBackgroundColor: containerColor);

  @override
  BalancePageTheme get balancePageTheme => super.balancePageTheme.copyWith(
      textColor: Colors.white,
      labelTextColor: Colors.grey,
      assetTitleColor: Colors.white,
      balanceAmountColor: Colors.white);

  @override
  DashboardPageTheme get dashboardPageTheme => super.dashboardPageTheme.copyWith(
      textColor: Colors.black,
      cardTextColor: Colors.white,
      mainActionsIconColor: Colors.white,
      indicatorDotTheme:
          IndicatorDotTheme(indicatorColor: Colors.grey, activeIndicatorColor: Colors.black));

  @override
  ExchangePageTheme get exchangePageTheme => super.exchangePageTheme.copyWith(
      firstGradientTopPanelColor: primaryColor, firstGradientBottomPanelColor: containerColor);

  @override
  SendPageTheme get sendPageTheme => super.sendPageTheme.copyWith(
      templateTitleColor: Colors.white,
      templateBackgroundColor: Colors.black,
      firstGradientColor: primaryColor);

  @override
  AddressTheme get addressTheme => super.addressTheme.copyWith(actionButtonColor: Colors.grey);

  @override
  FilterTheme get filterTheme => super.filterTheme.copyWith(iconColor: Colors.white);

  @override
  CakeMenuTheme get menuTheme => super.menuTheme.copyWith(
      settingTitleColor: Colors.black,
      headerFirstGradientColor: containerColor,
      iconColor: Colors.white);

  @override
  PickerTheme get pickerTheme => super.pickerTheme.copyWith(
      searchIconColor: primaryColor,
      searchHintColor: primaryColor,
      searchTextColor: primaryColor,
      searchBackgroundFillColor: Colors.white,
      searchBorderColor: primaryColor);

  @override
  AccountListTheme get accountListTheme => super.accountListTheme.copyWith(
      tilesTextColor: Colors.black,
      tilesBackgroundColor: Colors.white,
      currentAccountBackgroundColor: containerColor,
      currentAccountTextColor: Colors.white,
      currentAccountAmountColor: Colors.white);

  @override
  ReceivePageTheme get receivePageTheme => super.receivePageTheme.copyWith(
      tilesTextColor: Colors.white, iconsBackgroundColor: Colors.grey, iconsColor: Colors.black);

  @override
  OptionTileTheme get optionTileTheme => OptionTileTheme(
      titleColor: Colors.white, descriptionColor: Colors.white, useDarkImage: false);

  @override
  ThemeData get themeData => super.themeData.copyWith(
      disabledColor: Colors.grey,
      dialogTheme: super.themeData.dialogTheme.copyWith(backgroundColor: Colors.white));
}
