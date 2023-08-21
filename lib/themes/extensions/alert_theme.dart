import 'package:flutter/material.dart';

class AlertTheme extends ThemeExtension<AlertTheme> {
  final Color leftButtonTextColor;
  final Color backdropColor;

  AlertTheme({required this.leftButtonTextColor, required this.backdropColor});

  @override
  AlertTheme copyWith({Color? leftButtonTextColor, Color? backdropColor}) =>
      AlertTheme(
          leftButtonTextColor: leftButtonTextColor ?? this.leftButtonTextColor,
          backdropColor: backdropColor ?? this.backdropColor);

  @override
  AlertTheme lerp(ThemeExtension<AlertTheme>? other, double t) {
    if (other is! AlertTheme) {
      return this;
    }

    return AlertTheme(
        leftButtonTextColor:
            Color.lerp(leftButtonTextColor, other.leftButtonTextColor, t) ??
                leftButtonTextColor,
        backdropColor:
            Color.lerp(backdropColor, other.backdropColor, t) ?? backdropColor);
  }
}
