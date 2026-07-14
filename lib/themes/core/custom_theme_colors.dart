import 'package:flutter/material.dart';

/// Abstract interface for theme-specific custom colors
/// Each theme implementation should provide its own custom colors
abstract class CustomThemeColors {
  // Warning colors
  Color get warningContainerColor;
  Color get warningOutlineColor;

  // Background gradient colors
  Color get backgroundMainColor;
  Color get backgroundGradientColor;

  // Card gradient colors
  Color get cardGradientColorPrimary;
  Color get cardGradientColorSecondary;

  // Toggle colors
  Color get toggleKnobStateColor;
  Color get toggleColorOffState;

  // Sync colors (common across themes)
  static const syncGreen = Color(0xFFFF12A439);
  static const syncYellow = Color(0xFFFFFB84E);
}
