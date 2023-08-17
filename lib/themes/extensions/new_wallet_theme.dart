import 'package:flutter/material.dart';

class NewWalletTheme extends ThemeExtension<NewWalletTheme> {
  final Color hintTextColor;
  final Color underlineColor;

  NewWalletTheme({required this.hintTextColor, required this.underlineColor});

  @override
  Object get type => NewWalletTheme;

  @override
  NewWalletTheme copyWith({Color? hintTextColor, Color? underlineColor}) =>
      NewWalletTheme(
          hintTextColor: hintTextColor ?? this.hintTextColor,
          underlineColor: underlineColor ?? this.underlineColor);

  @override
  NewWalletTheme lerp(ThemeExtension<NewWalletTheme>? other, double t) {
    if (other is! NewWalletTheme) {
      return this;
    }

    return NewWalletTheme(
        hintTextColor:
            Color.lerp(hintTextColor, other.hintTextColor, t) ?? hintTextColor,
        underlineColor: Color.lerp(underlineColor, other.underlineColor, t) ??
            underlineColor);
  }
}
