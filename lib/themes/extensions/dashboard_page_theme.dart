import 'package:cake_wallet/themes/extensions/indicator_dot_theme.dart';
import 'package:flutter/material.dart';

class DashboardPageTheme extends ThemeExtension<DashboardPageTheme> {
  final Color firstGradientBackgroundColor;
  final Color secondGradientBackgroundColor;
  final Color thirdGradientBackgroundColor;
  final Color textColor;
  final Color cardTextColor;
  final Color pageTitleTextColor;
  final Color mainActionsIconColor;

  final IndicatorDotTheme indicatorDotTheme;

  DashboardPageTheme(
      {required this.firstGradientBackgroundColor,
      required this.secondGradientBackgroundColor,
      required this.thirdGradientBackgroundColor,
      required this.textColor,
      required this.indicatorDotTheme,
      Color? mainActionsIconColor,
      Color? pageTitleTextColor,
      Color? cardTextColor})
      : pageTitleTextColor = pageTitleTextColor ?? textColor,
        mainActionsIconColor = mainActionsIconColor ?? textColor,
        cardTextColor = cardTextColor ?? textColor;

  @override
  DashboardPageTheme copyWith(
          {Color? firstGradientBackgroundColor,
          Color? secondGradientBackgroundColor,
          Color? thirdGradientBackgroundColor,
          Color? textColor,
          IndicatorDotTheme? indicatorDotTheme,
          Color? pageTitleTextColor,
          Color? mainActionsIconColor,
          Color? cardTextColor}) =>
      DashboardPageTheme(
          firstGradientBackgroundColor:
              firstGradientBackgroundColor ?? this.firstGradientBackgroundColor,
          secondGradientBackgroundColor: secondGradientBackgroundColor ??
              this.secondGradientBackgroundColor,
          thirdGradientBackgroundColor:
              thirdGradientBackgroundColor ?? this.thirdGradientBackgroundColor,
          textColor: textColor ?? this.textColor,
          indicatorDotTheme: indicatorDotTheme ?? this.indicatorDotTheme,
          pageTitleTextColor: pageTitleTextColor ?? this.pageTitleTextColor,
          mainActionsIconColor:
              mainActionsIconColor ?? this.mainActionsIconColor,
          cardTextColor: cardTextColor ?? this.cardTextColor);

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
        textColor: Color.lerp(textColor, other.textColor, t) ?? textColor,
        indicatorDotTheme: indicatorDotTheme.lerp(other.indicatorDotTheme, t),
        pageTitleTextColor:
            Color.lerp(pageTitleTextColor, other.pageTitleTextColor, t) ??
                pageTitleTextColor,
        mainActionsIconColor:
            Color.lerp(mainActionsIconColor, other.mainActionsIconColor, t) ??
                mainActionsIconColor,
        cardTextColor:
            Color.lerp(cardTextColor, other.cardTextColor, t) ?? cardTextColor);
  }
}
