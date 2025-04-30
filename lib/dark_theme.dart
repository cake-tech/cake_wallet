import 'package:flutter/material.dart';

class BaseThemeV2 {
  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0x91A7FF),
      onPrimary: Color(0x002860),
      primaryContainer: Color(0x004C9E),
      onPrimaryContainer: Color(0xFFF3F0),
      secondary: Color(0xA1B9FF),
      onSecondary: Color(0x0C1C58),
      secondaryContainer: Color(0x1A3C6C),
      onSecondaryContainer: Color(0xBACBFF),
      error: Color(0xFFB4AB),
      onError: Color(0x690005),
      errorContainer: Color(0xB71919),
      onErrorContainer: Color(0xFFDAD6),
      background: Color(0x1B284A),
      backgroundGradient: Color(0x171E30),
      surface: Color(0x1D2541),
      onSurface: Color(0xD7E2F7),
      surfaceVariant: Color(0x3B3F59),
      onSurfaceVariant: Color(0xA3AFB9),
      surfaceContainerLowest: Color(0x171C30),
      surfaceContainerLow: Color(0x2D385C),
      surfaceContainer: Color(0x24335B),
      surfaceContainerHigh: Color(0x212C47),
      surfaceContainerHighest: Color(0x2A3B67),
    ),
  );
}
