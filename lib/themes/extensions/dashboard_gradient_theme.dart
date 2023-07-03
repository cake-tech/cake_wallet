import 'package:flutter/material.dart';

class DashboardGradientTheme extends ThemeExtension<DashboardGradientTheme> {
  final Color firstGradientColor;
  final Color secondGradientColor;
  final Color thirdGradientColor;

  DashboardGradientTheme(
      {required this.firstGradientColor,
      required this.secondGradientColor,
      required this.thirdGradientColor});

  @override
  Object get type => DashboardGradientTheme;

  @override
  DashboardGradientTheme copyWith(
          {Color? firstGradientColor,
          Color? secondGradientColor,
          Color? thirdGradientColor}) =>
      DashboardGradientTheme(
          firstGradientColor: firstGradientColor ?? this.firstGradientColor,
          secondGradientColor: secondGradientColor ?? this.secondGradientColor,
          thirdGradientColor: thirdGradientColor ?? this.thirdGradientColor);

  @override
  DashboardGradientTheme lerp(ThemeExtension<DashboardGradientTheme>? other, double t) {
    if (other is! DashboardGradientTheme) {
      return this;
    }

    return DashboardGradientTheme(
        firstGradientColor:
            Color.lerp(firstGradientColor, other.firstGradientColor, t)!,
        secondGradientColor:
            Color.lerp(secondGradientColor, other.secondGradientColor, t)!,
        thirdGradientColor:
            Color.lerp(thirdGradientColor, other.thirdGradientColor, t)!);
  }
}

