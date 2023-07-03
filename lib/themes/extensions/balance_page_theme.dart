import 'package:flutter/material.dart';

class BalancePageTheme extends ThemeExtension<BalancePageTheme> {
  final Color textColor;

  BalancePageTheme({required this.textColor});

  @override
  BalancePageTheme copyWith({Color? textColor}) =>
      BalancePageTheme(textColor: textColor ?? this.textColor);

  @override
  BalancePageTheme lerp(ThemeExtension<BalancePageTheme>? other, double t) {
    if (other is! BalancePageTheme) {
      return this;
    }

    return BalancePageTheme(
      textColor: Color.lerp(textColor, other.textColor, t) ?? textColor,
    );
  }
}
