# Material 3 Theming System

This directory contains the Material 3 (M3) theming implementation for Cake Wallet. The theming system is now fully based on Material 3 color tokens and patterns, with all custom theme extensions removed for simplicity, maintainability, and compliance with Material Design 3 guidelines.

## Directory Structure

```
lib/themes/
├── core/                # Theme state management and base theme logic
├── theme_classes/       # Light and dark theme data definitions
├── extensions/          # (Optional) Theme extensions for specific widgets/pages
├── utils/               # Utilities for theme management
└── README.md            # This file
```

## Key Features

- Material 3 color system with semantic color tokens
- Dynamic color support (when available)
- MobX-based state management
- Simplified theme management
- Consistent design language across the app

## Usage

### Accessing Theme Colors

```dart
final colorScheme = Theme.of(context).colorScheme;
final primaryColor = colorScheme.primary;
final onSurfaceVariant = colorScheme.onSurfaceVariant;
```

### Available Color Tokens

Material 3 provides a comprehensive set of semantic color tokens that adapt to light/dark themes:

- `primary` / `onPrimary`
- `secondary` / `onSecondary`
- `tertiary` / `onTertiary`
- `error` / `onError`
- `background` / `onBackground`
- `surface` / `onSurface`
- `surfaceVariant` / `onSurfaceVariant`
- `outline`, `outlineVariant`
- ...and more (see Flutter's ColorScheme)

### Theme Management

Theme mode state (light/dark/system) and switching is handled via MobX stores in `core/`. Use the provided store to get/set the current theme mode and listen for changes.

```dart
// Example: Getting the current theme mode
final themeStore = ... // Obtain from provider or context
final isDark = themeStore.isDark;

// Example: Switching theme mode
await themeStore.setThemeMode(ThemeMode.dark);
```

## Best Practices

1. **Always use semantic color tokens** from `ColorScheme` instead of hardcoded colors.
2. **Leverage Material 3 components** wherever possible for consistency and accessibility.
3. **Use the MobX theme store** for all theme-related state and switching.
4. **Test in both light and dark modes** to ensure good contrast and appearance.
5. **Keep any theme extensions minimal and focused** (if used at all).
6. **Do not reintroduce custom theme extensions** unless absolutely necessary and not covered by Material 3.

## Adding or Modifying Themes

- To update theme colors, edit the files in `theme_classes/` (e.g., `light_theme.dart`, `dark_theme.dart`).
- To add a new theme variant, create a new file in `theme_classes/` and update the MobX store in `core/` to support it.
- For widget-specific theming, prefer using Material 3's built-in tokens. Only use a theme extension if there is no Material 3 equivalent.

## Contributing

- Follow Material 3 color system and accessibility guidelines.
- Ensure proper contrast ratios for accessibility.
- Test all changes in both light and dark modes.
- Update this documentation if you add new color tokens or theme variants.
- Keep theme files organized and focused. 