import 'package:flutter/material.dart';

class WalletListTheme extends ThemeExtension<WalletListTheme> {
  final Color restoreWalletButtonTextColor;
  final Color createNewWalletButtonBackgroundColor;

  WalletListTheme(
      {required this.restoreWalletButtonTextColor,
      required this.createNewWalletButtonBackgroundColor});

  @override
  WalletListTheme copyWith(
          {Color? restoreWalletButtonTextColor,
          Color? createNewWalletButtonBackgroundColor}) =>
      WalletListTheme(
          restoreWalletButtonTextColor:
              restoreWalletButtonTextColor ?? this.restoreWalletButtonTextColor,
          createNewWalletButtonBackgroundColor:
              createNewWalletButtonBackgroundColor ??
                  this.createNewWalletButtonBackgroundColor);

  @override
  WalletListTheme lerp(ThemeExtension<WalletListTheme>? other, double t) {
    if (other is! WalletListTheme) {
      return this;
    }

    return WalletListTheme(
        restoreWalletButtonTextColor: Color.lerp(restoreWalletButtonTextColor,
                other.restoreWalletButtonTextColor, t) ??
            restoreWalletButtonTextColor,
        createNewWalletButtonBackgroundColor: Color.lerp(
                createNewWalletButtonBackgroundColor,
                other.createNewWalletButtonBackgroundColor,
                t) ??
            createNewWalletButtonBackgroundColor);
  }
}
