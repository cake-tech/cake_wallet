import 'package:flutter/material.dart';

class ReceivePageTheme extends ThemeExtension<ReceivePageTheme> {
  final Color currentTileBackgroundColor;
  final Color currentTileTextColor;
  final Color tilesBackgroundColor;
  final Color tilesTextColor;
  final Color iconsBackgroundColor;
  final Color iconsColor;
  final Color amountBottomBorderColor;
  final Color amountHintTextColor;

  ReceivePageTheme(
      {required this.currentTileBackgroundColor,
      required this.currentTileTextColor,
      required this.tilesBackgroundColor,
      required this.tilesTextColor,
      required this.iconsBackgroundColor,
      required this.iconsColor,
      required this.amountBottomBorderColor,
      required this.amountHintTextColor});

  @override
  ReceivePageTheme copyWith(
          {Color? currentTileBackgroundColor,
          Color? currentTileTextColor,
          Color? tilesBackgroundColor,
          Color? tilesTextColor,
          Color? iconsBackgroundColor,
          Color? iconsColor,
          Color? amountBottomBorderColor,
          Color? amountHintTextColor}) =>
      ReceivePageTheme(
          currentTileBackgroundColor:
              currentTileBackgroundColor ?? this.currentTileBackgroundColor,
          currentTileTextColor:
              currentTileTextColor ?? this.currentTileTextColor,
          tilesBackgroundColor:
              tilesBackgroundColor ?? this.tilesBackgroundColor,
          tilesTextColor: tilesTextColor ?? this.tilesTextColor,
          iconsBackgroundColor:
              iconsBackgroundColor ?? this.iconsBackgroundColor,
          iconsColor: iconsColor ?? this.iconsColor,
          amountBottomBorderColor:
              amountBottomBorderColor ?? this.amountBottomBorderColor,
          amountHintTextColor: amountHintTextColor ?? this.amountHintTextColor);

  @override
  ReceivePageTheme lerp(ThemeExtension<ReceivePageTheme>? other, double t) {
    if (other is! ReceivePageTheme) {
      return this;
    }

    return ReceivePageTheme(
        currentTileBackgroundColor: Color.lerp(
            currentTileBackgroundColor, other.currentTileBackgroundColor, t)!,
        currentTileTextColor:
            Color.lerp(currentTileTextColor, other.currentTileTextColor, t)!,
        tilesBackgroundColor:
            Color.lerp(tilesBackgroundColor, other.tilesBackgroundColor, t)!,
        tilesTextColor: Color.lerp(tilesTextColor, other.tilesTextColor, t)!,
        iconsBackgroundColor:
            Color.lerp(iconsBackgroundColor, other.iconsBackgroundColor, t)!,
        iconsColor: Color.lerp(iconsColor, other.iconsColor, t)!,
        amountBottomBorderColor: Color.lerp(
            amountBottomBorderColor, other.amountBottomBorderColor, t)!,
        amountHintTextColor:
            Color.lerp(amountHintTextColor, other.amountHintTextColor, t)!);
  }
}
