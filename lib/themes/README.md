# Material 3 Theming System

This directory contains the Material 3 (M3) theming implementation for Cake Wallet. The new theming system is designed to be more maintainable, scalable, and compliant with Material Design 3 guidelines while ensuring a seamless transition from the existing theme system.

## Directory Structure

```
lib/themes/m3/
├── base/
│   └── app_theme_data.dart      # Base theme data class
├── themes/
│   ├── app_light_theme.dart     # Light theme implementation
│   └── app_dark_theme.dart      # Dark theme implementation
├── theme_manager.dart           # Theme state management
├── theme_extensions.dart        # Convenience extensions
└── README.md                   # This file
```

## Key Features

- Material 3 color system with semantic color tokens
- Dynamic color support (when available)
- MobX-based state management
- Simplified theme management
- Seamless migration path from existing themes
- Consistent design language across the app

## Usage

### Accessing Theme Colors

```dart
// Using the theme directly
final colors = Theme.of(context).colorScheme;
final primaryColor = colors.primary;
final onPrimaryColor = colors.onPrimary;

// Using the convenience extension (optional)
final colors = context.colors;
final primaryColor = colors.primary;
```

### Available Color Tokens

The Material 3 color system provides semantic color tokens that automatically adapt to light/dark themes:

- `primary` / `onPrimary`: Primary brand color and its contrast color
- `secondary` / `onSecondary`: Secondary brand color and its contrast color
- `tertiary` / `onTertiary`: Tertiary color for accents and its contrast color
- `error` / `onError`: Error states and their contrast colors
- `background` / `onBackground`: Background colors and their contrast colors
- `surface` / `onSurface`: Surface colors and their contrast colors
- `surfaceVariant` / `onSurfaceVariant`: Variant surface colors
- `outline`: Color for outlines and dividers

### Adding New Themes

1. Create a new theme file in the `themes` directory:

```dart
// lib/themes/m3/themes/app_custom_theme.dart
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/m3/base/app_theme_data.dart';
import 'package:cake_wallet/palette.dart';

class AppCustomTheme extends AppThemeData {
  AppCustomTheme({required this.seedColor});

  @override
  final Color seedColor;

  @override
  Brightness get brightness => Brightness.light; // or dark

  @override
  Color get primaryColor => Palette.yourColor;

  // ... implement other required properties
}
```

2. Update the theme manager to support the new theme:

```dart
// In theme_manager.dart
AppThemeData get currentTheme {
  switch (_themeType) {
    case ThemeType.custom:
      return AppCustomTheme(seedColor: _seedColor);
    // ... other cases
  }
}
```

### Theme Manager

The theme manager handles:
- Theme mode (light/dark/system)
- Theme switching
- Theme persistence
- Dynamic color support

```dart
// Get the current theme
final themeManager = ThemeManager.of(context);
final isDark = themeManager.isDarkMode;

// Switch themes
themeManager.setThemeMode(ThemeMode.dark);

// Listen to theme changes (using MobX)
// TODO: Add MobX store example
```

## Migration Guide

1. Replace direct color usage with semantic color tokens:
   ```dart
   // Before
   color: Palette.blueCraiola
   
   // After
   color: Theme.of(context).colorScheme.primary
   ```

2. Update custom widgets to use Material 3 components where possible

3. Replace custom theme extensions with Material 3 equivalents:
   ```dart
   // Before
   context.theme.primaryColor
   
   // After
   context.colors.primary
   ```

4. For custom components that need specific theming, use `ThemeExtension`:
   ```dart
   class CustomComponentTheme extends ThemeExtension<CustomComponentTheme> {
     final Color customColor;
     
     CustomComponentTheme({required this.customColor});
     
     @override
     ThemeExtension<CustomComponentTheme> copyWith({Color? customColor}) {
       return CustomComponentTheme(
         customColor: customColor ?? this.customColor,
       );
     }
   }
   ```

## Best Practices

1. Always use semantic color tokens instead of hardcoded colors
2. Leverage Material 3 components when possible
3. Use the theme manager for theme-related operations
4. Keep custom theme extensions minimal and focused
5. Test themes in both light and dark modes
6. Consider dynamic color support for Android 12+ devices
7. Use MobX for theme state management
8. Follow the directory structure when adding new themes

## Contributing

When adding new themes or modifying existing ones:

1. Follow Material 3 color system guidelines
2. Ensure proper contrast ratios for accessibility
3. Test in both light and dark modes
4. Update documentation for any new theme tokens
5. Consider adding preview screenshots for new themes
6. Add MobX store integration for theme changes
7. Keep theme files separate and focused 