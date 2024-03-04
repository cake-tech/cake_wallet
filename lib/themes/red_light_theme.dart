import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/monero_light_theme.dart';
import 'package:flutter/material.dart';

class RedLightTheme extends MoneroLightTheme {
  RedLightTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.red_light_theme;
  @override
  Color get primaryColor => Palette.darkRed;
}