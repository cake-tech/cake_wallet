import 'package:flutter/material.dart';

class AccountListTheme extends ThemeExtension<AccountListTheme> {
  final Color tilesTextColor;
  final Color tilesBackgroundColor;

  AccountListTheme(
      {required this.tilesTextColor, required this.tilesBackgroundColor});

  @override
  AccountListTheme copyWith(
          {Color? tilesTextColor, Color? tilesBackgroundColor}) =>
      AccountListTheme(
          tilesTextColor: tilesTextColor ?? this.tilesTextColor,
          tilesBackgroundColor:
              tilesBackgroundColor ?? this.tilesBackgroundColor);

  @override
  AccountListTheme lerp(ThemeExtension<AccountListTheme>? other, double t) {
    if (other is! AccountListTheme) {
      return this;
    }

    return AccountListTheme(
        tilesTextColor: Color.lerp(tilesTextColor, other.tilesTextColor, t)!,
        tilesBackgroundColor:
            Color.lerp(tilesBackgroundColor, other.tilesBackgroundColor, t)!);
  }
}
