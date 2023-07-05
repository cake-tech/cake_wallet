import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/alert_theme.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_scrollbar_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/indicator_dot_theme.dart';
import 'package:cake_wallet/themes/extensions/info_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/new_wallet_theme.dart';
import 'package:cake_wallet/themes/extensions/order_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/pin_code_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/extensions/support_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class DarkTheme extends ThemeBase {
  DarkTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.dark_theme;
  @override
  ThemeType get type => ThemeType.dark;
  @override
  Brightness get brightness => Brightness.dark;
  @override
  Color get backgroundColor => PaletteDark.backgroundColor;
  @override
  Color get primaryColor => Palette.blueCraiola;
  @override
  Color get primaryTextColor => Colors.white;
  @override
  Color get containerColor => PaletteDark.nightBlue;
  @override
  Color get dialogBackgroundColor => PaletteDark.darkNightBlue;

  @override
  CakeScrollbarTheme get scrollbarTheme => CakeScrollbarTheme(
      thumbColor: PaletteDark.wildBlueGrey, trackColor: PaletteDark.violetBlue);

  @override
  SyncIndicatorTheme get syncIndicatorStyle => SyncIndicatorTheme(
      textColor: PaletteDark.wildBlue,
      syncedBackgroundColor: PaletteDark.lightNightBlue,
      notSyncedIconColor: PaletteDark.orangeYellow,
      notSyncedBackgroundColor: PaletteDark.oceanBlue);

  @override
  KeyboardTheme get keyboardTheme =>
      KeyboardTheme(keyboardBarColor: PaletteDark.granite);

  @override
  PinCodeTheme get pinCodeTheme => PinCodeTheme(
      indicatorsColor: PaletteDark.indicatorVioletBlue,
      switchColor: PaletteDark.lightPurpleBlue);

  @override
  SupportPageTheme get supportPageTheme =>
      SupportPageTheme(iconColor: Colors.white);

  @override
  ExchangePageTheme get exchangePageTheme => ExchangePageTheme(
      hintTextColor: PaletteDark.lightBlueGrey,
      dividerCodeColor: PaletteDark.deepVioletBlue,
      qrCodeColor: primaryTextColor,
      buttonBackgroundColor: PaletteDark.deepVioletBlue,
      textFieldButtonColor: PaletteDark.moderateBlue,
      textFieldBorderBottomPanelColor: PaletteDark.moderateVioletBlue,
      textFieldBorderTopPanelColor: PaletteDark.blueGrey,
      secondGradientBottomPanelColor: PaletteDark.darkNightBlue,
      firstGradientBottomPanelColor: PaletteDark.darkNightBlue,
      secondGradientTopPanelColor: PaletteDark.wildVioletBlue,
      firstGradientTopPanelColor: PaletteDark.wildVioletBlue,
      receiveAmountColor: PaletteDark.darkCyanBlue);

  @override
  NewWalletTheme get newWalletTheme => NewWalletTheme(
      hintTextColor: PaletteDark.cyanBlue,
      underlineColor: PaletteDark.darkGrey);

  @override
  BalancePageTheme get balancePageTheme =>
      BalancePageTheme(textColor: PaletteDark.cyanBlue);

  @override
  AddressTheme get addressTheme =>
      AddressTheme(actionButtonColor: PaletteDark.nightBlue);

  @override
  DashboardPageTheme get dashboardPageTheme =>
      super.dashboardPageTheme.copyWith(
          indicatorDotTheme: IndicatorDotTheme(
              indicatorColor: PaletteDark.cyanBlue,
              activeIndicatorColor: Colors.white));

  @override
  CakeMenuTheme get menuTheme => CakeMenuTheme(
      headerFirstGradientColor: PaletteDark.deepPurpleBlue,
      headerSecondGradientColor: PaletteDark.deepPurpleBlue,
      backgroundColor: PaletteDark.deepPurpleBlue,
      subnameTextColor: PaletteDark.darkCyanBlue,
      dividerColor: PaletteDark.darkOceanBlue,
      iconColor: PaletteDark.pigeonBlue);

  @override
  FilterTheme get filterTheme => FilterTheme(
      checkboxBoundsColor: PaletteDark.wildVioletBlue,
      checkboxBackgroundColor: PaletteDark.wildVioletBlue.withOpacity(0.3),
      titlesColor: Colors.white,
      buttonColor: PaletteDark.oceanBlue,
      iconColor: PaletteDark.wildBlue);

  @override
  WalletListTheme get walletListTheme => WalletListTheme(
      restoreWalletButtonTextColor: Palette.darkBlueCraiola,
      createNewWalletButtonBackgroundColor: Colors.white);

  @override
  InfoTheme get infoTheme => InfoTheme(textColor: Palette.darkLavender);

  @override
  PickerTheme get pickerTheme =>
      PickerTheme(dividerColor: PaletteDark.dividerColor);

  @override
  AlertTheme get alertTheme =>
      AlertTheme(leftButtonTextColor: Palette.alizarinRed);

  @override
  OrderTheme get orderTheme => OrderTheme(iconColor: Colors.white);

  @override
  SendPageTheme get sendPageTheme => SendPageTheme(
      templateTitleColor: PaletteDark.cyanBlue,
      templateBackgroundColor: PaletteDark.darkVioletBlue,
      templateNewTextColor: PaletteDark.darkCyanBlue,
      templateDottedBorderColor: PaletteDark.darkCyanBlue,
      estimatedFeeColor: Colors.white,
      textFieldButtonIconColor: PaletteDark.gray,
      textFieldButtonColor: PaletteDark.buttonNightBlue,
      textFieldHintColor: PaletteDark.darkCyanBlue,
      textFieldBorderColor: PaletteDark.lightVioletBlue,
      secondGradientColor: PaletteDark.darkNightBlue,
      firstGradientColor: PaletteDark.darkNightBlue);

  @override
  ThemeData get themeData => super.themeData.copyWith(
      indicatorColor: PaletteDark.cyanBlue, // page indicator
      hoverColor: PaletteDark.cyanBlue, // amount hint text (receive page)
      dividerColor: PaletteDark.dividerColor,
      hintColor: PaletteDark.pigeonBlue,
      disabledColor: PaletteDark.deepVioletBlue,
      dialogTheme: super
          .themeData
          .dialogTheme
          .copyWith(backgroundColor: PaletteDark.nightBlue),
      textTheme: TextTheme(
          labelSmall: TextStyle(
              backgroundColor: PaletteDark.darkCyanBlue, // date section row
              decorationColor: PaletteDark
                  .wildNightBlue // icons (transaction and trade rows)
              ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
            color: PaletteDark.nightBlue, // address button border
            decorationColor: PaletteDark.lightBlueGrey, // copy button (qr widget)
          ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: PaletteDark.lightBlueGrey, // qr code
            decorationColor: PaletteDark.darkGrey, // bottom border of amount (receive page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
            color: Colors.white, // icons color (receive page)
            decorationColor: PaletteDark.distantNightBlue, // icons background (receive page)
          ),
          // display2 -> displaySmall
          displaySmall: TextStyle(
              color: Colors.white, // text color of tiles (receive page)
              decorationColor:
                  PaletteDark.nightBlue // background of tiles (receive page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: Palette
                  .blueCraiola, // text color of current tile (receive page)
              decorationColor: PaletteDark
                  .lightOceanBlue // background of current tile (receive page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
              color: Colors.white, // text color of tiles (account list)
              decorationColor: PaletteDark
                  .darkOceanBlue // background of tiles (account list)
              ),
      ),
      primaryTextTheme: TextTheme(
          // title -> titleLarge
          titleLarge: TextStyle(
              color: Colors.white, // title color
              backgroundColor: PaletteDark.darkOceanBlue // textfield underline
              ),
          bodySmall: TextStyle(
              color: PaletteDark.darkCyanBlue, // secondary text
              ),
          labelSmall: TextStyle(
            color:
                PaletteDark.lightBlueGrey, // transaction/trade details titles
            decorationColor: Colors.grey, // placeholder
          ),
      ),
      );
}
