import 'package:cake_wallet/themes/extensions/account_list_theme.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/alert_theme.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_scrollbar_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/indicator_dot_theme.dart';
import 'package:cake_wallet/themes/extensions/info_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/new_wallet_theme.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/order_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/pin_code_theme.dart';
import 'package:cake_wallet/themes/extensions/placeholder_theme.dart';
import 'package:cake_wallet/themes/extensions/qr_code_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/extensions/support_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
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
      indicatorsColor: Palette.darkGray, switchColor: Palette.darkGray);

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
  AddressTheme get addressTheme =>
      AddressTheme(actionButtonColor: Palette.shadowWhite);

  @override
  DashboardPageTheme get dashboardPageTheme =>
      super.dashboardPageTheme.copyWith(
          cardTextColor: super.dashboardPageTheme.textColor,
          indicatorDotTheme: IndicatorDotTheme(
              indicatorColor: PaletteDark.darkCyanBlue.withOpacity(0.67),
              activeIndicatorColor: PaletteDark.darkNightBlue));

  @override
  BalancePageTheme get balancePageTheme => BalancePageTheme(
      textColor: dashboardPageTheme.textColor,
      labelTextColor: Palette.darkBlueCraiola.withOpacity(0.67));

  @override
  CakeMenuTheme get menuTheme => CakeMenuTheme(
      headerFirstGradientColor: Palette.blueCraiola,
      headerSecondGradientColor: Palette.blueGreyCraiola,
      backgroundColor: Colors.white,
      subnameTextColor: Colors.white,
      dividerColor: Palette.wildLavender,
      iconColor: Colors.white,
      settingTitleColor: receivePageTheme.tilesTextColor,
      settingActionsIconColor: Palette.gray);

  @override
  FilterTheme get filterTheme => FilterTheme(
      checkboxFirstGradientColor: Palette.blueCraiola,
      checkboxSecondGradientColor: Palette.blueGreyCraiola,
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
  PickerTheme get pickerTheme => PickerTheme(
      dividerColor: Palette.periwinkleCraiola,
      searchTextColor: cakeTextTheme.textfieldUnderlineColor,
      searchBackgroundFillColor: addressTheme.actionButtonColor);

  @override
  AlertTheme get alertTheme => AlertTheme(
      backdropColor: PaletteDark.darkNightBlue.withOpacity(0.75),
      leftButtonTextColor: Palette.brightOrange);

  @override
  OrderTheme get orderTheme => OrderTheme(iconColor: Colors.black);

  @override
  SendPageTheme get sendPageTheme => SendPageTheme(
      templateTitleColor: Palette.darkBlueCraiola,
      templateBackgroundColor: Palette.blueAlice,
      templateNewTextColor: Palette.darkBlueCraiola,
      templateDottedBorderColor: Palette.moderateLavender,
      templateSelectedCurrencyBackgroundColor: Colors.white,
      templateSelectedCurrencyTitleColor: primaryColor,
      estimatedFeeColor: Colors.white.withOpacity(0.5),
      textFieldButtonIconColor: Colors.white,
      textFieldButtonColor: Colors.white.withOpacity(0.2),
      textFieldHintColor: Colors.white.withOpacity(0.5),
      textFieldBorderColor: Colors.white.withOpacity(0.5),
      secondGradientColor: Palette.blueGreyCraiola,
      firstGradientColor: Palette.blueCraiola,
      indicatorDotColor: PaletteDark.darkCyanBlue.withOpacity(0.67));

  @override
  SeedWidgetTheme get seedWidgetTheme =>
      SeedWidgetTheme(hintTextColor: Palette.darkGray);

  @override
  PlaceholderTheme get placeholderTheme =>
      PlaceholderTheme(color: PaletteDark.darkCyanBlue);

  @override
  TransactionTradeTheme get transactionTradeTheme => TransactionTradeTheme(
      detailsTitlesColor: Palette.darkGray, rowsColor: Palette.blueAlice);

  @override
  CakeTextTheme get cakeTextTheme => CakeTextTheme(
      secondaryTextColor: PaletteDark.pigeonBlue,
      textfieldUnderlineColor: Palette.wildPeriwinkle,
      titleColor: Palette.violetBlue,
      addressButtonBorderColor: Palette.blueAlice,
      dateSectionRowColor: PaletteDark.darkCyanBlue);

  @override
  AccountListTheme get accountListTheme => AccountListTheme(
      currentAccountBackgroundColor: dialogBackgroundColor,
      currentAccountTextColor: primaryColor,
      currentAccountAmountColor: receivePageTheme.iconsColor,
      tilesBackgroundColor: Colors.white,
      tilesAmountColor: receivePageTheme.iconsColor,
      tilesTextColor: Palette.violetBlue);

  @override
  ReceivePageTheme get receivePageTheme => ReceivePageTheme(
      currentTileBackgroundColor: Palette.blueCraiola,
      currentTileTextColor: Colors.white,
      tilesBackgroundColor: Palette.blueAlice,
      tilesTextColor: Palette.darkBlueCraiola,
      iconsBackgroundColor: Palette.moderateLavender,
      iconsColor: PaletteDark.lightBlueGrey,
      amountBottomBorderColor: Palette.darkBlueCraiola,
      amountHintTextColor: Palette.darkBlueCraiola);

  @override
  QRCodeTheme get qrCodeTheme => QRCodeTheme(
      qrCodeColor: Colors.white,
      qrWidgetCopyButtonColor: PaletteDark.lightBlueGrey);

  @override
  OptionTileTheme get optionTileTheme => OptionTileTheme(
      titleColor: primaryTextColor, descriptionColor: primaryTextColor, useDarkImage: true);

  @override
  ThemeData get themeData => super.themeData.copyWith(
      dividerColor: Palette.paleBlue,
      hintColor: Palette.gray,
      disabledColor: Palette.darkGray,
      dialogTheme:
          super.themeData.dialogTheme.copyWith(backgroundColor: Colors.white));
}
