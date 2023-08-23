import 'package:flutter/material.dart';

class SeedWidgetTheme extends ThemeExtension<SeedWidgetTheme> {
  final Color hintTextColor;

  SeedWidgetTheme({required this.hintTextColor});

  @override
  SeedWidgetTheme copyWith({Color? hintTextColor}) =>
      SeedWidgetTheme(hintTextColor: hintTextColor ?? this.hintTextColor);

  @override
  SeedWidgetTheme lerp(ThemeExtension<SeedWidgetTheme>? other, double t) {
    if (other is! SeedWidgetTheme) {
      return this;
    }

    return SeedWidgetTheme(
        hintTextColor:
            Color.lerp(hintTextColor, other.hintTextColor, t) ?? hintTextColor);
  }
}
