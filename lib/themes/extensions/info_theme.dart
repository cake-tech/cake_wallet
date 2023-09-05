import 'package:flutter/material.dart';

class InfoTheme extends ThemeExtension<InfoTheme> {
  final Color textColor;

  InfoTheme({required this.textColor});

  @override
  InfoTheme copyWith({Color? textColor}) =>
      InfoTheme(textColor: textColor ?? this.textColor);

  @override
  InfoTheme lerp(ThemeExtension<InfoTheme>? other, double t) {
    if (other is! InfoTheme) {
      return this;
    }

    return InfoTheme(
        textColor: Color.lerp(textColor, other.textColor, t) ?? textColor);
  }
}
