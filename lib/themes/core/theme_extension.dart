import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:flutter/material.dart';

/// For access to the current theme that we would have had to do a lot of constructor pass down for.
extension ThemeX on BuildContext {
  MaterialThemeBase get currentTheme => getIt<ThemeStore>().currentTheme;
  CustomThemeColors get customColors => currentTheme.customColors;
}
