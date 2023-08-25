import 'package:flutter/material.dart';

class PinCodeTheme extends ThemeExtension<PinCodeTheme> {
  final Color indicatorsColor;
  final Color switchColor;

  PinCodeTheme({required this.indicatorsColor, required this.switchColor});

  @override
  PinCodeTheme copyWith({Color? indicatorsColor, Color? switchColor}) =>
      PinCodeTheme(
          indicatorsColor: indicatorsColor ?? this.indicatorsColor,
          switchColor: switchColor ?? this.switchColor);

  @override
  PinCodeTheme lerp(ThemeExtension<PinCodeTheme>? other, double t) {
    if (other is! PinCodeTheme) {
      return this;
    }

    return PinCodeTheme(
        indicatorsColor:
            Color.lerp(indicatorsColor, other.indicatorsColor, t) ??
                indicatorsColor,
        switchColor:
            Color.lerp(switchColor, other.switchColor, t) ?? switchColor);
  }
}
