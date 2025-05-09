import 'package:flutter/material.dart';

class BaseThemeV2 {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0x4EBEFF),
      onPrimary: Color(0xFFFFFF),
      primaryContainer: Color(0x403747),
      onPrimaryContainer: Color(0xD5C8DC),
      secondary: Color(0x625C64),
      onSecondary: Color(0xFFFFFF),
      secondaryContainer: Color(0xE1E4EA),
      onSecondaryContainer: Color(0x4C474E),
      error: Color(0xBA1A1A),
      onError: Color(0xFFFFFF),
      errorContainer: Color(0xFFBDBD),
      onErrorContainer: Color(0xE43D3D),
      //backgroundGradient: Color(0xDFE3E7),
      surface: Color(0xEFEFF8),
      onSurface: Color(0x312938),
      onSurfaceVariant: Color(0x6C6772),
      surfaceContainerLowest: Color(0xFFFFFF),
      surfaceContainerLow: Color(0xF2F3F7),
      surfaceContainer: Color(0xFBFBFD),
      surfaceContainerHigh: Color(0xFDFDFE),
      surfaceContainerHighest: Color(0xFFFFFF),
    ),
  );
}
