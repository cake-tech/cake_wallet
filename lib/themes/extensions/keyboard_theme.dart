import 'package:flutter/material.dart';

class KeyboardTheme extends ThemeExtension<KeyboardTheme> {
  final Color keyboardBarColor;

  KeyboardTheme({required this.keyboardBarColor});

  @override
  Object get type => KeyboardTheme;

  @override
  KeyboardTheme copyWith({Color? keyboardBarColor}) => KeyboardTheme(
      keyboardBarColor: keyboardBarColor ?? this.keyboardBarColor);

  @override
  KeyboardTheme lerp(ThemeExtension<KeyboardTheme>? other, double t) {
    if (other is! KeyboardTheme) {
      return this;
    }

    return KeyboardTheme(
        keyboardBarColor:
            Color.lerp(keyboardBarColor, other.keyboardBarColor, t) ??
                keyboardBarColor);
  }
}
