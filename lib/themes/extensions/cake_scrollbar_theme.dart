import 'package:flutter/material.dart';

class CakeScrollbarTheme extends ThemeExtension<CakeScrollbarTheme> {
  final Color thumbColor;
  final Color trackColor;

  CakeScrollbarTheme({required this.thumbColor, required this.trackColor});

  @override
  Object get type => CakeScrollbarTheme;

  @override
  CakeScrollbarTheme copyWith({Color? thumbColor, Color? trackColor}) =>
      CakeScrollbarTheme(
          thumbColor: thumbColor ?? this.thumbColor,
          trackColor: trackColor ?? this.trackColor);

  @override
  CakeScrollbarTheme lerp(ThemeExtension<CakeScrollbarTheme>? other, double t) {
    if (other is! CakeScrollbarTheme) {
      return this;
    }

    return CakeScrollbarTheme(
        thumbColor: Color.lerp(thumbColor, other.thumbColor, t) ?? thumbColor,
        trackColor: Color.lerp(trackColor, other.trackColor, t) ?? trackColor);
  }
}
