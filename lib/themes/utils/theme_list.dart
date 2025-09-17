import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/theme_classes/dark_theme.dart';
import 'package:cake_wallet/themes/theme_classes/light_theme.dart';
import 'package:cake_wallet/themes/theme_classes/black_theme.dart';

class ThemeList {
  static final all = [
    darkTheme,
    lightTheme,
    blackThemeCakePrimary,
    blackThemeBCHGreen,
    blackThemeBitcoinYellow,
    blackThemeMoneroOrange,
    blackThemeTronRed,
    blackThemeFrostingPurple,
  ];

  static final lightTheme = LightTheme();
  static final darkTheme = DarkTheme();
  static final blackThemeCakePrimary = BlackTheme(BlackThemeAccentColor.cakePrimary);
  static final blackThemeBitcoinYellow = BlackTheme(BlackThemeAccentColor.bitcoinYellow);
  static final blackThemeBCHGreen = BlackTheme(BlackThemeAccentColor.bchGreen);
  static final blackThemeMoneroOrange = BlackTheme(BlackThemeAccentColor.moneroOrange);
  static final blackThemeTronRed = BlackTheme(BlackThemeAccentColor.tronRed);
  static final blackThemeFrostingPurple = BlackTheme(BlackThemeAccentColor.frostingPurple);

  static MaterialThemeBase deserialize({required int raw}) {
    switch (raw) {
      case 0:
      case 2:
      case 4:
      case 5:
      case 7:
      case 10:
      case 11:
        return lightTheme;
      case 1:
      case 3:
      case 6:
      case 8:
      case 9:
        return darkTheme;
      case 12:
        return blackThemeCakePrimary;
      case 13:
        return blackThemeBCHGreen;
      case 14:
        return blackThemeBitcoinYellow;
      case 15:
        return blackThemeMoneroOrange;
      case 16:
        return blackThemeTronRed;
      case 17:
        return blackThemeFrostingPurple;
      default:
        return blackThemeCakePrimary;
    }
  }
}
