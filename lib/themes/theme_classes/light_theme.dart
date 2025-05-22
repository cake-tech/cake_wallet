import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';

/// Light theme implementation using Material 3
class LightTheme extends MaterialThemeBase {
  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primaryColor => const Color(0xFF4EBEFF);

  @override
  Color get secondaryColor => const Color(0xFF625C64);

  // @override
  // Color get tertiaryColor => const Color(0xFF403747);

  @override
  Color get errorColor => const Color(0xFFBA1A1A);

  @override
  Color get surfaceColor => const Color(0xFFEFEFF8);

  @override
  ColorScheme get colorScheme => ColorScheme.light(
        primary: primaryColor,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFF403747),
        onPrimaryContainer: const Color(0xFFD5C8DC),
        secondary: secondaryColor,
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: const Color(0xFFE1E4EA),
        onSecondaryContainer: const Color(0xFF4C474E),
        error: errorColor,
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFFFBDBD),
        onErrorContainer: const Color(0xFFE43D3D),
        surface: surfaceColor,
        onSurface: const Color(0xFF312938),
        onSurfaceVariant: const Color(0xFF6C6772),
        surfaceContainerLowest: Color(0xFFE4E4E4),
        surfaceContainerLow: Color(0xFFECECED),
        surfaceContainer: Color(0xFFFBFBFD),
        surfaceContainerHigh: Color(0xFFFDFDFE),
        surfaceContainerHighest: Color(0xFFFFFFFF),

        // outline: const Color(0x6C6772),
        // outlineVariant: const Color(0xE1E4EA),
        // shadow: const Color(0xFF000000),
        // scrim: const Color(0xFF000000),
        // inverseSurface: const Color(0x312938),
        // onInverseSurface: const Color(0xEFEFF8),
        // inversePrimary: primaryColor.withAlpha(204),
        // surfaceTint: primaryColor.withAlpha(13),
        // tertiary: tertiaryColor,
        // onTertiary: const Color(0xFFFFFF),
        // tertiaryContainer: const Color(0xE1E4EA),
        // onTertiaryContainer: const Color(0x4C474E),
      );

  @override
  TextTheme get textTheme => TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: colorScheme.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: colorScheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: colorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: colorScheme.onSurface,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
      );

  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: colorScheme,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: colorScheme.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
        ),
      );

  @override
  String get title => 'Light Theme';

  @override
  ThemeType get type => ThemeType.light;

  @override
  int get raw => 0;
}
