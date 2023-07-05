import 'package:flutter/material.dart';

class AlertTheme extends ThemeExtension<AlertTheme> {
  final Color leftButtonTextColor;

  AlertTheme({required this.leftButtonTextColor});

  @override
  AlertTheme copyWith({Color? leftButtonTextColor}) => AlertTheme(
      leftButtonTextColor: leftButtonTextColor ?? this.leftButtonTextColor);

  @override
  AlertTheme lerp(ThemeExtension<AlertTheme>? other, double t) {
    if (other is! AlertTheme) {
      return this;
    }

    return AlertTheme(
        leftButtonTextColor:
            Color.lerp(leftButtonTextColor, other.leftButtonTextColor, t) ??
                leftButtonTextColor);
  }
}
