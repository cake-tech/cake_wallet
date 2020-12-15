import 'package:cake_wallet/src/themes/bright_theme.dart';
import 'package:cake_wallet/src/themes/dark_theme.dart';
import 'package:cake_wallet/src/themes/light_theme.dart';
import 'package:cake_wallet/src/themes/theme_base.dart';

class ThemeList {
  static final all = [lightTheme, brightTheme, darkTheme];

  static final lightTheme = LightTheme(raw: 0);
  static final brightTheme = BrightTheme(raw: 1);
  static final darkTheme = DarkTheme(raw: 2);

  static ThemeBase deserialize({int raw}) {
    switch (raw) {
      case 0:
        return lightTheme;
      case 1:
        return brightTheme;
      case 2:
        return darkTheme;
      default:
        return null;
    }
  }
}