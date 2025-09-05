import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/theme_classes/dark_theme.dart';
import 'package:cake_wallet/themes/theme_classes/light_theme.dart';
import 'package:cake_wallet/themes/theme_classes/black_theme.dart';

class ThemeList {
  static final all = [
    darkTheme,
    lightTheme,
    blackTheme,
  ];

  static final lightTheme = LightTheme();
  static final darkTheme = DarkTheme();
  static final blackTheme = BlackTheme();

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
        return blackTheme;
      default:
        return blackTheme;
    }
  }
}
