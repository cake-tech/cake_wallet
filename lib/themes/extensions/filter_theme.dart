import 'package:flutter/material.dart';

class FilterTheme extends ThemeExtension<FilterTheme> {
  final Color checkboxFirstGradientColor;
  final Color checkboxSecondGradientColor;
  final Color checkboxBoundsColor;
  final Color checkboxBackgroundColor;
  final Color titlesColor;
  final Color buttonColor;
  final Color iconColor;

  FilterTheme(
      {required this.checkboxFirstGradientColor,
      required this.checkboxSecondGradientColor,
      required this.checkboxBoundsColor,
      required this.checkboxBackgroundColor,
      required this.titlesColor,
      required this.buttonColor,
      required this.iconColor});

  @override
  FilterTheme copyWith({
    Color? checkboxFirstGradientColor,
    Color? checkboxSecondGradientColor,
    Color? checkboxBoundsColor,
    Color? checkboxBackgroundColor,
    Color? titlesColor,
    Color? buttonColor,
    Color? iconColor,
  }) =>
      FilterTheme(
          checkboxFirstGradientColor:
              checkboxFirstGradientColor ?? this.checkboxFirstGradientColor,
          checkboxSecondGradientColor:
              checkboxSecondGradientColor ?? this.checkboxSecondGradientColor,
          checkboxBoundsColor: checkboxBoundsColor ?? this.checkboxBoundsColor,
          checkboxBackgroundColor:
              checkboxBackgroundColor ?? this.checkboxBackgroundColor,
          titlesColor: titlesColor ?? this.titlesColor,
          buttonColor: buttonColor ?? this.buttonColor,
          iconColor: iconColor ?? this.iconColor);

  @override
  FilterTheme lerp(ThemeExtension<FilterTheme>? other, double t) {
    if (other is! FilterTheme) {
      return this;
    }

    return FilterTheme(
        checkboxFirstGradientColor: Color.lerp(checkboxFirstGradientColor,
                other.checkboxFirstGradientColor, t) ??
            this.checkboxFirstGradientColor,
        checkboxSecondGradientColor: Color.lerp(checkboxSecondGradientColor,
                other.checkboxSecondGradientColor, t) ??
            this.checkboxSecondGradientColor,
        checkboxBoundsColor:
            Color.lerp(checkboxBoundsColor, other.checkboxBoundsColor, t) ??
                this.checkboxBoundsColor,
        checkboxBackgroundColor: Color.lerp(
                checkboxBackgroundColor, other.checkboxBackgroundColor, t) ??
            this.checkboxBackgroundColor,
        titlesColor:
            Color.lerp(titlesColor, other.titlesColor, t) ?? this.titlesColor,
        buttonColor:
            Color.lerp(buttonColor, other.buttonColor, t) ?? this.buttonColor,
        iconColor: Color.lerp(iconColor, other.iconColor, t) ?? this.iconColor);
  }
}
