import 'package:cake_wallet/themes/extensions/account_list_theme.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/alert_theme.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/indicator_dot_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/new_wallet_theme.dart';
import 'package:cake_wallet/themes/extensions/qr_code_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/themes/light_theme.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class MoneroLightTheme extends LightTheme {
  MoneroLightTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.monero_light_theme;
  @override
  Color get primaryColor => Palette.moneroOrange;
  @override
  Color get containerColor => Palette.moneroLightOrange;
  @override
  Color get primaryTextColor => colorScheme.onPrimaryContainer;
  @override
  Color get dialogBackgroundColor => containerColor;

  @override
  SyncIndicatorTheme get syncIndicatorStyle =>
      super.syncIndicatorStyle.copyWith(
          textColor: primaryTextColor,
          syncedBackgroundColor: colorScheme.primaryContainer,
          notSyncedBackgroundColor: containerColor.withOpacity(0.75));

  @override
  ExchangePageTheme get exchangePageTheme => super.exchangePageTheme.copyWith(
      qrCodeColor: primaryTextColor,
      buttonBackgroundColor: containerColor,
      secondGradientBottomPanelColor: primaryColor.withOpacity(0.7),
      firstGradientBottomPanelColor: colorScheme.primary.withOpacity(0.7),
      secondGradientTopPanelColor: primaryColor,
      firstGradientTopPanelColor: colorScheme.primary,
      textFieldBorderBottomPanelColor: colorScheme.surfaceVariant,
      textFieldBorderTopPanelColor: colorScheme.surfaceVariant,
      receiveAmountColor: colorScheme.surfaceVariant);

  @override
  NewWalletTheme get newWalletTheme => super.newWalletTheme.copyWith(
      hintTextColor: colorScheme.secondary,
      underlineColor: colorScheme.secondary);

  @override
  AddressTheme get addressTheme =>
      super.addressTheme.copyWith(actionButtonColor: containerColor);

  @override
  DashboardPageTheme get dashboardPageTheme =>
      super.dashboardPageTheme.copyWith(
          indicatorDotTheme: IndicatorDotTheme(
              indicatorColor: colorScheme.secondaryContainer,
              activeIndicatorColor: colorScheme.inversePrimary));
  @override
  BalancePageTheme get balancePageTheme => super.balancePageTheme.copyWith(
      textColor: primaryTextColor.withOpacity(0.67),
      labelTextColor: colorScheme.secondary);

  @override
  CakeMenuTheme get menuTheme => super.menuTheme.copyWith(
      headerFirstGradientColor: colorScheme.primary,
      headerSecondGradientColor: primaryColor,
      dividerColor: colorScheme.secondaryContainer,
      iconColor: colorScheme.secondaryContainer,
      settingActionsIconColor: colorScheme.secondary);

  @override
  FilterTheme get filterTheme => super.filterTheme.copyWith(
      checkboxFirstGradientColor: colorScheme.secondaryContainer,
      checkboxSecondGradientColor: colorScheme.inversePrimary,
      checkboxBoundsColor: PaletteDark.wildVioletBlue,
      checkboxBackgroundColor: PaletteDark.wildVioletBlue.withOpacity(0.3),
      buttonColor: containerColor,
      iconColor: colorScheme.secondary);

  @override
  WalletListTheme get walletListTheme => super.walletListTheme.copyWith(
      restoreWalletButtonTextColor: Colors.white,
      createNewWalletButtonBackgroundColor: primaryColor);

  @override
  SendPageTheme get sendPageTheme => super.sendPageTheme.copyWith(
      templateTitleColor: primaryTextColor,
      templateBackgroundColor: containerColor,
      templateNewTextColor: primaryTextColor,
      templateDottedBorderColor: colorScheme.primaryContainer,
      secondGradientColor: primaryColor,
      firstGradientColor: colorScheme.primary,
      indicatorDotColor: dashboardPageTheme.indicatorDotTheme.indicatorColor);

  @override
  SeedWidgetTheme get seedWidgetTheme =>
      super.seedWidgetTheme.copyWith(hintTextColor: colorScheme.secondary);

  @override
  TransactionTradeTheme get transactionTradeTheme =>
      super.transactionTradeTheme.copyWith(
          detailsTitlesColor: colorScheme.secondary, rowsColor: containerColor);

  @override
  CakeTextTheme get cakeTextTheme => super.cakeTextTheme.copyWith(
      titleColor: primaryTextColor,
      secondaryTextColor: colorScheme.secondary,
      addressButtonBorderColor: primaryColor.withOpacity(0.2),
      dateSectionRowColor: colorScheme.secondary,
      textfieldUnderlineColor: colorScheme.secondary.withOpacity(0.5));

  @override
  AccountListTheme get accountListTheme =>
      super.accountListTheme.copyWith(tilesBackgroundColor: containerColor);

  @override
  ReceivePageTheme get receivePageTheme => super.receivePageTheme.copyWith(
      currentTileBackgroundColor: primaryColor,
      tilesBackgroundColor: containerColor,
      tilesTextColor: primaryTextColor,
      iconsBackgroundColor: colorScheme.surfaceVariant,
      iconsColor: colorScheme.onSurfaceVariant,
      amountBottomBorderColor: primaryTextColor,
      amountHintTextColor: primaryTextColor,
      currentTileTextColor: Colors.white);

  @override
  QRCodeTheme get qrCodeTheme => super
      .qrCodeTheme
      .copyWith(qrWidgetCopyButtonColor: colorScheme.secondary);

  @override
  AlertTheme get alertTheme => super
      .alertTheme
      .copyWith(backdropColor: colorScheme.inverseSurface.withOpacity(0.75));

  @override
  ThemeData get themeData => super.themeData.copyWith(
      dividerColor: pickerTheme.dividerColor,
      hintColor: colorScheme.secondary,
      dialogTheme: super
          .themeData
          .dialogTheme
          .copyWith(backgroundColor: containerColor));
}
