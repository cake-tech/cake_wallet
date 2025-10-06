import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:cake_wallet/themes/custom_theme_colors/dark_theme_custom_colors.dart';

class DarkTheme extends MaterialThemeBase {
  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeMode get themeMode => ThemeMode.dark;

  @override
  Color get primaryColor => const Color(0xFF91B0FF);

  @override
  Color get secondaryColor => const Color(0xFFA1B9FF);

  @override
  Color get errorColor => const Color(0xFFFFB4AB);

  @override
  Color get surfaceColor => const Color(0xFF1B284A);

  @override
  Color get tertiaryColor => const Color(0xFF162028);

  @override
  ColorScheme get colorScheme => ColorScheme.dark(
        primary: primaryColor,
        onPrimary: const Color(0xFF002860),
        primaryContainer: const Color(0xFF004C9E),
        onPrimaryContainer: const Color(0xFFFFF3F0),
        secondary: secondaryColor,
        onSecondary: const Color(0xFF0C1C58),
        secondaryContainer: const Color(0xFF1A3C6C),
        onSecondaryContainer: const Color(0xFFBACBFF),
        tertiary: tertiaryColor,
        onTertiary: const Color(0xFF2B373F),
        tertiaryContainer: const Color(0xFF1F2832),
        onTertiaryContainer: const Color(0xFFA8B3C6),
        error: errorColor,
        onError: const Color(0xFFB71919),
        errorContainer: const Color(0xFFC53636),
        onErrorContainer: const Color(0xFFFFDAD6),
        surface: surfaceColor,
        onSurface: const Color(0xFFD7E2F7),
        onSurfaceVariant: const Color(0xFF8C9FBB),
        surfaceContainerLowest: Color(0xFF171C30),
        surfaceContainerLow: Color(0xFF2D385C),
        surfaceContainer: Color(0xFF24335B),
        surfaceContainerHigh: Color(0xFF212C47),
        surfaceContainerHighest: Color(0xFF2A3B67),
        outline: const Color(0xFF9EACC1),
        outlineVariant: const Color(0xFF3E5579),
      );
  static const String fontFamily = 'Lato';
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
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
      );

  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        brightness: brightness,
        colorScheme: colorScheme,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.error),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );

  @override
  String get title => 'Dark Theme';

  @override
  ThemeType get type => ThemeType.dark;

  @override
  int get raw => 1;

  @override
  CustomThemeColors get customColors => DarkThemeCustomColors();

  @override
  String? get themeFamily => null;

  @override
  String? get accentColorId => null;

  @override
  String? get accentColorName => null;
}
