import 'package:flutter/material.dart';

class SupportPageTheme extends ThemeExtension<SupportPageTheme> {
  final Color iconColor;

  SupportPageTheme({required this.iconColor});

  @override
  SupportPageTheme copyWith({Color? iconColor}) =>
      SupportPageTheme(iconColor: iconColor ?? this.iconColor);

  @override
  SupportPageTheme lerp(ThemeExtension<SupportPageTheme>? other, double t) {
    if (other is! SupportPageTheme) {
      return this;
    }

    return SupportPageTheme(
        iconColor: Color.lerp(iconColor, other.iconColor, t) ?? iconColor);
  }
}
