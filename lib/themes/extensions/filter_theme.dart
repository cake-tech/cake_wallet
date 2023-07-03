import 'package:flutter/material.dart';

class FilterTheme extends ThemeExtension<FilterTheme> {
  final Color checkboxBoundsColor;
  final Color checkboxBackgroundColor;
  final Color titlesColor;
  final Color buttonColor;
  final Color iconColor;

  FilterTheme(
      {required this.checkboxBoundsColor,
      required this.checkboxBackgroundColor,
      required this.titlesColor,
      required this.buttonColor,
      required this.iconColor});

  @override
  FilterTheme copyWith({
    Color? checkboxBoundsColor,
    Color? checkboxBackgroundColor,
    Color? titlesColor,
    Color? buttonColor,
    Color? iconColor,
  }) =>
      FilterTheme(
        checkboxBoundsColor: checkboxBoundsColor ?? this.checkboxBoundsColor,
        checkboxBackgroundColor:
            checkboxBackgroundColor ?? this.checkboxBackgroundColor,
        titlesColor: titlesColor ?? this.titlesColor,
        buttonColor: buttonColor ?? this.buttonColor,
        iconColor: iconColor ?? this.iconColor,
      );

  @override
  FilterTheme lerp(ThemeExtension<FilterTheme>? other, double t) {
    if (other is! FilterTheme) {
      return this;
    }

    return FilterTheme(
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
