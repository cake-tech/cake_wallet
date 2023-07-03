import 'package:flutter/material.dart';

class DashboardPageTheme extends ThemeExtension<DashboardPageTheme> {
  final Color firstGradientBackgroundColor;
  final Color secondGradientBackgroundColor;
  final Color thirdGradientBackgroundColor;
  final Color textColor;

  DashboardPageTheme(
      {required this.firstGradientBackgroundColor,
      required this.secondGradientBackgroundColor,
      required this.thirdGradientBackgroundColor,
      required this.textColor});

  @override
  Object get type => DashboardPageTheme;

  @override
  DashboardPageTheme copyWith(
          {Color? firstGradientBackgroundColor,
          Color? secondGradientBackgroundColor,
          Color? thirdGradientBackgroundColor,
          Color? textColor}) =>
      DashboardPageTheme(
          firstGradientBackgroundColor:
              firstGradientBackgroundColor ?? this.firstGradientBackgroundColor,
          secondGradientBackgroundColor: secondGradientBackgroundColor ??
              this.secondGradientBackgroundColor,
          thirdGradientBackgroundColor:
              thirdGradientBackgroundColor ?? this.thirdGradientBackgroundColor,
          textColor: textColor ?? this.textColor);

  @override
  DashboardPageTheme lerp(ThemeExtension<DashboardPageTheme>? other, double t) {
    if (other is! DashboardPageTheme) {
      return this;
    }

    return DashboardPageTheme(
        firstGradientBackgroundColor: Color.lerp(firstGradientBackgroundColor,
                other.firstGradientBackgroundColor, t) ??
            firstGradientBackgroundColor,
        secondGradientBackgroundColor: Color.lerp(secondGradientBackgroundColor,
                other.secondGradientBackgroundColor, t) ??
            secondGradientBackgroundColor,
        thirdGradientBackgroundColor: Color.lerp(thirdGradientBackgroundColor,
                other.thirdGradientBackgroundColor, t) ??
            thirdGradientBackgroundColor,
        textColor: Color.lerp(textColor, other.textColor, t) ?? textColor);
  }
}
