import 'package:flutter/material.dart';

enum ThemeType { light, dark }

/// Abstract base class for theme data in the app.
/// This class defines the contract that all theme implementations must follow.
abstract class MaterialThemeBase {
  int get raw;

  String get title;

  ThemeMode get themeMode;

  ThemeType get type;

  Color get errorColor;

  Color get surfaceColor;

  Color get primaryColor;

  Color get secondaryColor;

  Brightness get brightness;

  ColorScheme get colorScheme;

  Color get tertiaryColor;

  TextTheme get textTheme;

  ThemeData get themeData;

  bool get isDark => brightness == Brightness.dark;
}
