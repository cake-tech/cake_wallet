import 'package:flutter/material.dart';

class IndicatorDotTheme extends ThemeExtension<IndicatorDotTheme> {
  final Color indicatorColor;
  final Color activeIndicatorColor;

  IndicatorDotTheme(
      {required this.indicatorColor, required this.activeIndicatorColor});

  @override
  IndicatorDotTheme copyWith(
          {Color? indicatorColor, Color? actionButtonColor}) =>
      IndicatorDotTheme(
          indicatorColor: indicatorColor ?? this.indicatorColor,
          activeIndicatorColor: actionButtonColor ?? this.activeIndicatorColor);

  @override
  IndicatorDotTheme lerp(ThemeExtension<IndicatorDotTheme>? other, double t) {
    if (other is! IndicatorDotTheme) {
      return this;
    }

    return IndicatorDotTheme(
        indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t) ??
            indicatorColor,
        activeIndicatorColor:
            Color.lerp(activeIndicatorColor, other.activeIndicatorColor, t) ??
                activeIndicatorColor);
  }
}
