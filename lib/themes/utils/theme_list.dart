import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/theme_classes/dark_theme.dart';
import 'package:cake_wallet/themes/theme_classes/light_theme.dart';

class ThemeList {
  static final all = [
    darkTheme,
    lightTheme,
  ];

  static final lightTheme = LightTheme();
  static final darkTheme = DarkTheme();

  static MaterialThemeBase deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return lightTheme;
      case 1:
        return darkTheme;
      default:
        throw Exception('Unexpected token raw: $raw for deserialization of MaterialBaseTheme');
    }
  }
}
