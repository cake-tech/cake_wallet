import 'package:flutter/material.dart';

class CakeTextTheme extends ThemeExtension<CakeTextTheme> {
  final Color secondaryTextColor;
  final Color textfieldUnderlineColor;
  final Color titleColor;

  CakeTextTheme(
      {required this.secondaryTextColor,
      required this.textfieldUnderlineColor,
      required this.titleColor});

  @override
  CakeTextTheme copyWith(
          {Color? secondaryTextColor,
          Color? textfieldUnderlineColor,
          Color? titleColor}) =>
      CakeTextTheme(
          secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
          textfieldUnderlineColor:
              textfieldUnderlineColor ?? this.textfieldUnderlineColor,
          titleColor: titleColor ?? this.titleColor);

  @override
  CakeTextTheme lerp(ThemeExtension<CakeTextTheme>? other, double t) {
    if (other is! CakeTextTheme) {
      return this;
    }

    return CakeTextTheme(
        secondaryTextColor:
            Color.lerp(secondaryTextColor, other.secondaryTextColor, t)!,
        textfieldUnderlineColor: Color.lerp(
            textfieldUnderlineColor, other.textfieldUnderlineColor, t)!,
        titleColor: Color.lerp(titleColor, other.titleColor, t)!);
  }
}
