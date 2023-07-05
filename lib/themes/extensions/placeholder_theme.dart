import 'package:flutter/material.dart';

class PlaceholderTheme extends ThemeExtension<PlaceholderTheme> {
  final Color color;

  PlaceholderTheme({required this.color});

  @override
  PlaceholderTheme copyWith({Color? color}) =>
      PlaceholderTheme(color: color ?? this.color);

  @override
  PlaceholderTheme lerp(ThemeExtension<PlaceholderTheme>? other, double t) {
    if (other is! PlaceholderTheme) {
      return this;
    }

    return PlaceholderTheme(color: Color.lerp(color, other.color, t) ?? color);
  }
}
