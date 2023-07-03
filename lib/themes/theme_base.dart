import 'package:cake_wallet/themes/extensions/dashboard_gradient_theme.dart';
import 'package:flutter/material.dart';

enum ThemeType { light, bright, dark }

abstract class ThemeBase {
  ThemeBase({required this.raw});

  final int raw;
  String get title;
  ThemeType get type;

  @override
  String toString() {
    return title;
  }

  Brightness get brightness;
  Color get backgroundColor;
  Color get primaryColor;
  Color get primaryTextColor;
  Color get containerColor;

  ColorScheme get colorScheme => ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: primaryColor,
      background: backgroundColor);

  DashboardGradientTheme get pageGradientTheme => DashboardGradientTheme(
      firstGradientColor: backgroundColor,
      secondGradientColor: backgroundColor,
      thirdGradientColor: backgroundColor);

  ThemeData get themeData => ThemeData.from(
          colorScheme: colorScheme,
          textTheme: TextTheme().apply(fontFamily: 'Lato'))
      .copyWith(
          primaryColor: primaryColor,
          cardColor: containerColor,
          extensions: [pageGradientTheme]);
}