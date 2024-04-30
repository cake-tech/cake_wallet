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
  AddressTheme get addressTheme =>
      AddressTheme(actionButtonColor: PaletteDark.nightBlue);

  @override
  DashboardPageTheme get dashboardPageTheme =>
      super.dashboardPageTheme.copyWith(
          cardTextColor: super.dashboardPageTheme.textColor,
          indicatorDotTheme: IndicatorDotTheme(
              indicatorColor: PaletteDark.cyanBlue,
              activeIndicatorColor: Colors.white));

  @override
  BalancePageTheme get balancePageTheme => BalancePageTheme(
      textColor: dashboardPageTheme.textColor,
      labelTextColor: PaletteDark.cyanBlue);

  @override
  CakeMenuTheme get menuTheme => CakeMenuTheme(
      headerFirstGradientColor: PaletteDark.deepPurpleBlue,
      headerSecondGradientColor: PaletteDark.deepPurpleBlue,
      backgroundColor: PaletteDark.deepPurpleBlue,
      subnameTextColor: PaletteDark.darkCyanBlue,
      dividerColor: PaletteDark.darkOceanBlue,
      settingTitleColor: receivePageTheme.tilesTextColor,
      settingActionsIconColor: PaletteDark.pigeonBlue,
      iconColor: PaletteDark.darkCyanBlue);

  @override
  FilterTheme get filterTheme => FilterTheme(
      checkboxFirstGradientColor: PaletteDark.darkNightBlue,
      checkboxSecondGradientColor: PaletteDark.darkNightBlue,
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
  PickerTheme get pickerTheme => PickerTheme(
      dividerColor: PaletteDark.dividerColor,
      searchTextColor: cakeTextTheme.textfieldUnderlineColor,
      searchBackgroundFillColor: addressTheme.actionButtonColor);

  @override
  AlertTheme get alertTheme => AlertTheme(
      backdropColor: PaletteDark.darkNightBlue.withOpacity(0.75),
      leftButtonTextColor: Palette.alizarinRed);

  @override
  OrderTheme get orderTheme => OrderTheme(iconColor: Colors.white);

  @override
  SendPageTheme get sendPageTheme => SendPageTheme(
      templateTitleColor: PaletteDark.cyanBlue,
      templateBackgroundColor: PaletteDark.darkVioletBlue,
      templateNewTextColor: PaletteDark.darkCyanBlue,
      templateDottedBorderColor: PaletteDark.darkCyanBlue,
      templateSelectedCurrencyBackgroundColor: primaryColor,
      templateSelectedCurrencyTitleColor: Colors.white,
      estimatedFeeColor: Colors.white,
      textFieldButtonIconColor: PaletteDark.gray,
      textFieldButtonColor: PaletteDark.buttonNightBlue,
      textFieldHintColor: PaletteDark.darkCyanBlue,
      textFieldBorderColor: PaletteDark.lightVioletBlue,
      secondGradientColor: PaletteDark.darkNightBlue,
      firstGradientColor: PaletteDark.darkNightBlue,
      indicatorDotColor: PaletteDark.cyanBlue);

  @override
  SeedWidgetTheme get seedWidgetTheme =>
      SeedWidgetTheme(hintTextColor: PaletteDark.darkCyanBlue);

  @override
  PlaceholderTheme get placeholderTheme => PlaceholderTheme(color: Colors.grey);

  @override
  TransactionTradeTheme get transactionTradeTheme => TransactionTradeTheme(
      detailsTitlesColor: PaletteDark.lightBlueGrey,
      rowsColor: PaletteDark.wildNightBlue);

  @override
  CakeTextTheme get cakeTextTheme => CakeTextTheme(
      secondaryTextColor: PaletteDark.darkCyanBlue,
      textfieldUnderlineColor: PaletteDark.darkOceanBlue,
      titleColor: Colors.white,
      addressButtonBorderColor: PaletteDark.nightBlue,
      dateSectionRowColor: PaletteDark.darkCyanBlue);

  @override
  AccountListTheme get accountListTheme => AccountListTheme(
      currentAccountBackgroundColor: dialogBackgroundColor,
      currentAccountTextColor: primaryColor,
      currentAccountAmountColor: receivePageTheme.iconsColor,
      tilesAmountColor: receivePageTheme.iconsColor,
      tilesBackgroundColor: PaletteDark.darkOceanBlue,
      tilesTextColor: Colors.white);

  @override
  ReceivePageTheme get receivePageTheme => ReceivePageTheme(
      currentTileBackgroundColor: PaletteDark.lightOceanBlue,
      currentTileTextColor: Palette.blueCraiola,
      tilesBackgroundColor: PaletteDark.nightBlue,
      tilesTextColor: Colors.white,
      iconsBackgroundColor: PaletteDark.distantNightBlue,
      iconsColor: Colors.white,
      amountBottomBorderColor: PaletteDark.darkGrey,
      amountHintTextColor: PaletteDark.cyanBlue);

  @override
  QRCodeTheme get qrCodeTheme => QRCodeTheme(
      qrCodeColor: PaletteDark.lightBlueGrey,
      qrWidgetCopyButtonColor: PaletteDark.lightBlueGrey);

  @override
  OptionTileTheme get optionTileTheme => OptionTileTheme(
      titleColor: primaryTextColor, descriptionColor: primaryTextColor, useDarkImage: false);

  @override
  ThemeData get themeData => super.themeData.copyWith(
      dividerColor: PaletteDark.dividerColor,
      hintColor: PaletteDark.pigeonBlue,
      disabledColor: PaletteDark.deepVioletBlue,
      dialogTheme: super
          .themeData
          .dialogTheme
          .copyWith(backgroundColor: PaletteDark.nightBlue));
}
