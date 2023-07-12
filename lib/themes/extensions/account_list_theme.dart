import 'package:flutter/material.dart';

class AccountListTheme extends ThemeExtension<AccountListTheme> {
  final Color tilesTextColor;
  final Color tilesAmountColor;
  final Color tilesBackgroundColor;
  final Color currentAccountBackgroundColor;
  final Color currentAccountTextColor;
  final Color currentAccountAmountColor;

  AccountListTheme(
      {required this.tilesTextColor,
      required this.tilesAmountColor,
      required this.tilesBackgroundColor,
      required this.currentAccountBackgroundColor,
      required this.currentAccountTextColor,
      required this.currentAccountAmountColor});

  @override
  AccountListTheme copyWith(
          {Color? tilesTextColor,
          Color? tilesAmountColor,
          Color? tilesBackgroundColor,
          Color? currentAccountBackgroundColor,
          Color? currentAccountTextColor,
          Color? currentAccountAmountColor}) =>
      AccountListTheme(
          tilesTextColor: tilesTextColor ?? this.tilesTextColor,
          tilesAmountColor: tilesAmountColor ?? this.tilesAmountColor,
          tilesBackgroundColor:
              tilesBackgroundColor ?? this.tilesBackgroundColor,
          currentAccountBackgroundColor: currentAccountBackgroundColor ??
              this.currentAccountBackgroundColor,
          currentAccountTextColor:
              currentAccountTextColor ?? this.currentAccountTextColor,
          currentAccountAmountColor:
              currentAccountAmountColor ?? this.currentAccountAmountColor);

  @override
  AccountListTheme lerp(ThemeExtension<AccountListTheme>? other, double t) {
    if (other is! AccountListTheme) {
      return this;
    }

    return AccountListTheme(
        tilesTextColor: Color.lerp(tilesTextColor, other.tilesTextColor, t)!,
        tilesAmountColor:
            Color.lerp(tilesAmountColor, other.tilesAmountColor, t)!,
        tilesBackgroundColor:
            Color.lerp(tilesBackgroundColor, other.tilesBackgroundColor, t)!,
        currentAccountBackgroundColor: Color.lerp(currentAccountBackgroundColor,
            other.currentAccountBackgroundColor, t)!,
        currentAccountTextColor: Color.lerp(
            currentAccountTextColor, other.currentAccountTextColor, t)!,
        currentAccountAmountColor: Color.lerp(
            currentAccountAmountColor, other.currentAccountAmountColor, t)!);
  }
}
