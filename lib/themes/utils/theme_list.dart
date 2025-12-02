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
  static final blackThemeCakePrimaryOled = BlackTheme(
    BlackThemeAccentColor.cakePrimary,
    isOled: true,
  );

  static final blackThemeBitcoinYellow = BlackTheme(BlackThemeAccentColor.bitcoinYellow);
  static final blackThemeBitcoinYellowOled = BlackTheme(
    BlackThemeAccentColor.bitcoinYellow,
    isOled: true,
  );

  static final blackThemeMoneroOrange = BlackTheme(BlackThemeAccentColor.moneroOrange);
  static final blackThemeMoneroOrangeOled = BlackTheme(
    BlackThemeAccentColor.moneroOrange,
    isOled: true,
  );

  static final blackThemeBCHGreen = BlackTheme(BlackThemeAccentColor.bchGreen);
  static final blackThemeBCHGreenOled = BlackTheme(
    BlackThemeAccentColor.bchGreen,
    isOled: true,
  );

  static final blackThemeTronRed = BlackTheme(BlackThemeAccentColor.tronRed);
  static final blackThemeTronRedOled = BlackTheme(
    BlackThemeAccentColor.tronRed,
    isOled: true,
  );

  static final blackThemeFrostingPurple = BlackTheme(BlackThemeAccentColor.frostingPurple);
  static final blackThemeFrostingPurpleOled = BlackTheme(
    BlackThemeAccentColor.frostingPurple,
    isOled: true,
  );

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
      case 112:
        return blackThemeCakePrimaryOled;
      case 113:
        return blackThemeBCHGreenOled;
      case 114:
        return blackThemeBitcoinYellowOled;
      case 115:
        return blackThemeMoneroOrangeOled;
      case 116:
        return blackThemeTronRedOled;
      case 117:
        return blackThemeFrostingPurpleOled;
      default:
        return blackThemeCakePrimary;
    }
  }
}
