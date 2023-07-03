import 'package:cake_wallet/themes/extensions/cake_scrollbar_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_gradient_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
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
  Color get dialogBackgroundColor;

  ColorScheme get colorScheme => ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: primaryColor,
      background: backgroundColor);

  ThemeData get generatedThemeData => ThemeData.from(
      colorScheme: colorScheme,
      textTheme: TextTheme().apply(fontFamily: 'Lato'));

  DashboardGradientTheme get pageGradientTheme => DashboardGradientTheme(
      firstGradientColor: backgroundColor,
      secondGradientColor: backgroundColor,
      thirdGradientColor: backgroundColor);

  CakeScrollbarTheme get scrollbarTheme;

  SyncIndicatorTheme get syncIndicatorStyle;

  ThemeData get themeData => generatedThemeData.copyWith(
      primaryColor: primaryColor,
      cardColor: containerColor,
      dialogBackgroundColor: dialogBackgroundColor,
      extensions: [
        pageGradientTheme,
        scrollbarTheme,
        syncIndicatorStyle
      ],
      scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(scrollbarTheme.thumbColor),
          trackColor: MaterialStateProperty.all(scrollbarTheme.trackColor),
          radius: Radius.circular(3),
          thickness: MaterialStateProperty.all(6),
          thumbVisibility: MaterialStateProperty.all(true),
          crossAxisMargin: 6));
}