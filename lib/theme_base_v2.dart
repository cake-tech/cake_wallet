import 'package:flutter/material.dart';

class BaseThemeV2 {
  static final ThemeData appTheme = ThemeData(
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: error,
      onError: onError,
      surface: surface,
      onSurface: onSurface,
    ),
  );
}
