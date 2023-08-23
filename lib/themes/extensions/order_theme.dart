import 'package:flutter/material.dart';

class OrderTheme extends ThemeExtension<OrderTheme> {
  final Color iconColor;

  OrderTheme({required this.iconColor});

  @override
  OrderTheme copyWith({Color? iconColor}) =>
      OrderTheme(iconColor: iconColor ?? this.iconColor);

  @override
  OrderTheme lerp(ThemeExtension<OrderTheme>? other, double t) {
    if (other is! OrderTheme) {
      return this;
    }

    return OrderTheme(
        iconColor: Color.lerp(iconColor, other.iconColor, t) ?? iconColor);
  }
}
