import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/monero_dark_theme.dart';
import 'package:flutter/material.dart';

class PurpleDarkTheme extends MoneroDarkTheme {
  PurpleDarkTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.purple_dark_theme;
  @override
  Color get primaryColor => PaletteDark.darkPurple;
}