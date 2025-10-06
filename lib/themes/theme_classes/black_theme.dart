import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:cake_wallet/themes/custom_theme_colors/black_theme_custom_colors.dart';

enum BlackThemeAccentColor implements ThemeAccentColor {
  cakePrimary(Color(0xFF52B6F0), 'Cake Primary'),
  bitcoinYellow(Color(0xFFFFC107), 'Bitcoin Yellow'),
  moneroOrange(Color(0xFFFF5F2A), 'Monero Orange');

  const BlackThemeAccentColor(this.color, this.name);

  @override
  final Color color;

  @override
  final String name;
}

class BlackTheme extends MaterialThemeBase {
  BlackTheme(this.accentColor, {this.isOled = false});

  final BlackThemeAccentColor accentColor;
  final bool isOled;

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeMode get themeMode => ThemeMode.dark;

  @override
  Color get primaryColor => accentColor.color;

  @override
  Color get secondaryColor => const Color(0xFFCCC4CD);

  @override
  Color get errorColor => const Color(0xFFFFB4AB);

  @override
  Color get surfaceColor => isOled ? const Color(0xFF000000) : const Color(0xFF131314);

  @override
  Color get tertiaryColor => const Color(0xFFDEBFC5);

  @override
  ColorScheme get colorScheme => ColorScheme.dark(
        primary: primaryColor,
        onPrimary: const Color(0xFF352D3C),
        primaryContainer: const Color(0xFF28212F),
        onPrimaryContainer: const Color(0xFFB7ABBE),
        secondary: secondaryColor,
        onSecondary: const Color(0xFF332F36),
        secondaryContainer: const Color(0xFF454148),
        onSecondaryContainer: const Color(0xFFDFD6DF),
        tertiary: tertiaryColor,
        onTertiary: const Color(0xFF3F2B30),
        tertiaryContainer: const Color(0xFF321F24),
        onTertiaryContainer: const Color(0xFFC6A8AE),
        error: errorColor,
        onError: const Color(0xFFB71919),
        errorContainer: const Color(0xFFC53636),
        onErrorContainer: const Color(0xFFFFDAD6),
        surface: surfaceColor,
        background: surfaceColor,
        onSurface: const Color(0xFFE6E1E3),
        onSurfaceVariant: const Color(0xFFB4B4B4),
        surfaceContainerLowest: isOled ? const Color(0xFF000000) : const Color(0xFF0F0E0F),
        surfaceContainerLow: Color(0xFF1C1B1C),
        surfaceContainer: Color(0xFF211F20),
        surfaceContainerHigh: Color(0xFF2B292B),
        surfaceContainerHighest: Color(0xFF363435),
        outline: const Color(0xFF958F95),
        outlineVariant: const Color(0xFF49454B),
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
        scaffoldBackgroundColor: surfaceColor,
        canvasColor: surfaceColor,
        cardColor: colorScheme.surface,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor,
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
  String get title => 'Black Theme (${accentColor.name})';

  @override
  ThemeType get type => ThemeType.dark;

  @override
  int get raw {
    final baseValue = switch (accentColor) {
      BlackThemeAccentColor.cakePrimary => 12,
      BlackThemeAccentColor.bitcoinYellow => 13,
      BlackThemeAccentColor.moneroOrange => 14,
    };
    if (!isOled) return baseValue;
    // OLED encodes as 100 + base to avoid collisions
    return 100 + baseValue;
  }

  @override
  CustomThemeColors get customColors => BlackThemeCustomColors();

  @override
  String? get themeFamily => 'BlackTheme';

  @override
  String? get accentColorId => accentColor.name.toLowerCase();

  @override
  String? get accentColorName => accentColor.name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlackTheme &&
          runtimeType == other.runtimeType &&
          accentColor == other.accentColor &&
          isOled == other.isOled;

  @override
  int get hashCode => Object.hash(accentColor, isOled);
}
