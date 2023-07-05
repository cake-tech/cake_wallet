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
import 'package:cake_wallet/themes/extensions/placeholder_theme.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/extensions/support_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class LightTheme extends ThemeBase {
  LightTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.light_theme;
  @override
  ThemeType get type => ThemeType.light;
  @override
  Brightness get brightness => Brightness.light;
  @override
  Color get backgroundColor => Colors.white;
  @override
  Color get primaryColor => Palette.protectiveBlue;
  @override
  Color get primaryTextColor => Palette.darkBlueCraiola;
  @override
  Color get containerColor => Palette.blueAlice;
  @override
  Color get dialogBackgroundColor => Colors.white;

  @override
  CakeScrollbarTheme get scrollbarTheme => CakeScrollbarTheme(
      thumbColor: Palette.moderatePurpleBlue,
      trackColor: Palette.periwinkleCraiola);

  @override
  SyncIndicatorTheme get syncIndicatorStyle => SyncIndicatorTheme(
      textColor: Palette.darkBlueCraiola,
      syncedBackgroundColor: Palette.blueAlice,
      notSyncedIconColor: Palette.shineOrange,
      notSyncedBackgroundColor: Palette.blueAlice.withOpacity(0.75));

  @override
  KeyboardTheme get keyboardTheme =>
      KeyboardTheme(keyboardBarColor: Palette.dullGray);

  @override
  PinCodeTheme get pinCodeTheme => PinCodeTheme(
      indicatorsColor: Palette.darkGray,
      switchColor: Palette.darkGray);

  @override
  SupportPageTheme get supportPageTheme =>
      SupportPageTheme(iconColor: Colors.black);

  @override
  ExchangePageTheme get exchangePageTheme => ExchangePageTheme(
      hintTextColor: Colors.white.withOpacity(0.4),
      dividerCodeColor: Palette.wildPeriwinkle,
      qrCodeColor: primaryTextColor,
      buttonBackgroundColor: containerColor,
      textFieldButtonColor: Colors.white.withOpacity(0.2),
      textFieldBorderBottomPanelColor: Colors.white.withOpacity(0.5),
      textFieldBorderTopPanelColor: Colors.white.withOpacity(0.5),
      secondGradientBottomPanelColor: Palette.blueGreyCraiola.withOpacity(0.7),
      firstGradientBottomPanelColor: Palette.blueCraiola.withOpacity(0.7),
      secondGradientTopPanelColor: Palette.blueGreyCraiola,
      firstGradientTopPanelColor: Palette.blueCraiola,
      receiveAmountColor: Palette.niagara);

  @override
  NewWalletTheme get newWalletTheme => NewWalletTheme(
      hintTextColor: Palette.darkGray,
      underlineColor: Palette.periwinkleCraiola);

  @override
  BalancePageTheme get balancePageTheme =>
      BalancePageTheme(textColor: Palette.darkBlueCraiola.withOpacity(0.67));

  @override
  AddressTheme get addressTheme =>
      AddressTheme(actionButtonColor: Palette.shadowWhite);

  @override
  DashboardPageTheme get dashboardPageTheme =>
      super.dashboardPageTheme.copyWith(
          indicatorDotTheme: IndicatorDotTheme(
              indicatorColor: PaletteDark.darkCyanBlue.withOpacity(0.67),
              activeIndicatorColor: PaletteDark.darkNightBlue));

  @override
  CakeMenuTheme get menuTheme => CakeMenuTheme(
      headerFirstGradientColor: Palette.blueCraiola,
      headerSecondGradientColor: Palette.blueGreyCraiola,
      backgroundColor: Colors.white,
      subnameTextColor: Colors.white,
      dividerColor: Palette.wildLavender,
      iconColor: Palette.gray);

  @override
  FilterTheme get filterTheme => FilterTheme(
      checkboxBoundsColor: Palette.wildPeriwinkle,
      checkboxBackgroundColor: Colors.white,
      titlesColor: Palette.darkGray,
      buttonColor: Palette.blueAlice,
      iconColor: PaletteDark.wildBlue);

  @override
  WalletListTheme get walletListTheme => WalletListTheme(
      restoreWalletButtonTextColor: Colors.white,
      createNewWalletButtonBackgroundColor: Palette.protectiveBlue);

  @override
  InfoTheme get infoTheme => InfoTheme(textColor: Palette.darkBlueCraiola);

  @override
  PickerTheme get pickerTheme =>
      PickerTheme(dividerColor: Palette.periwinkleCraiola);

  @override
  AlertTheme get alertTheme =>
      AlertTheme(leftButtonTextColor: Palette.brightOrange);

  @override
  OrderTheme get orderTheme => OrderTheme(iconColor: Colors.black);

  @override
  SendPageTheme get sendPageTheme => SendPageTheme(
      templateTitleColor: Palette.darkBlueCraiola,
      templateBackgroundColor: Palette.blueAlice,
      templateNewTextColor: Palette.darkBlueCraiola,
      templateDottedBorderColor: Palette.moderateLavender,
      estimatedFeeColor: Colors.white.withOpacity(0.5),
      textFieldButtonIconColor: Colors.white,
      textFieldButtonColor: Colors.white.withOpacity(0.2),
      textFieldHintColor: Colors.white.withOpacity(0.5),
      textFieldBorderColor: Colors.white.withOpacity(0.5),
      secondGradientColor: Palette.blueGreyCraiola,
      firstGradientColor: Palette.blueCraiola);

  @override
  SeedWidgetTheme get seedWidgetTheme =>
      SeedWidgetTheme(hintTextColor: Palette.darkGray);

  @override
  PlaceholderTheme get placeholderTheme =>
      PlaceholderTheme(color: PaletteDark.darkCyanBlue);

  @override
  ThemeData get themeData => super.themeData.copyWith(
      indicatorColor:
          PaletteDark.darkCyanBlue.withOpacity(0.67), // page indicator
      hoverColor: Palette.darkBlueCraiola, // amount hint text (receive page)
      dividerColor: Palette.paleBlue,
      hintColor: Palette.gray,
      disabledColor: Palette.darkGray,
      dialogTheme: super
          .themeData
          .dialogTheme
          .copyWith(backgroundColor: Colors.white),
      textTheme: TextTheme(
          labelSmall: TextStyle(
              backgroundColor: PaletteDark.darkCyanBlue, // date section row
              decorationColor:
                  Palette.blueAlice // icons (transaction and trade rows)
              ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
            color: Palette.blueAlice, // address button border
            decorationColor: PaletteDark.lightBlueGrey, // copy button (qr widget)
          ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: Colors.white, // qr code
            decorationColor: Palette.darkBlueCraiola, // bottom border of amount (receive page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
            color: PaletteDark.lightBlueGrey, // icons color (receive page)
            decorationColor: Palette.moderateLavender, // icons background (receive page)
          ),
          // display2 -> headldisplaySmalline3
          displaySmall: TextStyle(
              color:
                  Palette.darkBlueCraiola, // text color of tiles (receive page)
              decorationColor:
                  Palette.blueAlice // background of tiles (receive page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: Colors.white, // text color of current tile (receive page),
              //decorationColor: Palette.blueCraiola // background of current tile (receive page)
              decorationColor: Palette
                  .blueCraiola // background of current tile (receive page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
              color: Palette.violetBlue, // text color of tiles (account list)
              decorationColor:
                  Colors.white // background of tiles (account list)
              ),
      ),
      primaryTextTheme: TextTheme(
          // title -> titleLarge
          titleLarge: TextStyle(
              color: Palette.darkBlueCraiola, // title color
              backgroundColor: Palette.wildPeriwinkle // textfield underline
              ),
          bodySmall: TextStyle(
              color: PaletteDark.pigeonBlue, // secondary text
              ),
          labelSmall: TextStyle(
            color: Palette.darkGray, // transaction/trade details titles
          ),
      ),
      );
}
