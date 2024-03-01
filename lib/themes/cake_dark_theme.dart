import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/monero_dark_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';

class CakeDarkTheme extends MoneroDarkTheme {
  CakeDarkTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.cake_dark_theme;
  @override
  Color get primaryColor => PaletteDark.cakeBlue;

  @override
  CakeMenuTheme get menuTheme => super.menuTheme.copyWith(
      headerFirstGradientColor: PaletteDark.darkBlue,
      headerSecondGradientColor: containerColor,
      backgroundColor: containerColor,
      subnameTextColor: Colors.grey,
      dividerColor: colorScheme.secondaryContainer,
      iconColor: Colors.white,
      settingActionsIconColor: colorScheme.secondaryContainer);
}