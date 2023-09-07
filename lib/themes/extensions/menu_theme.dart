import 'package:flutter/material.dart';

class CakeMenuTheme extends ThemeExtension<CakeMenuTheme> {
  final Color headerFirstGradientColor;
  final Color headerSecondGradientColor;
  final Color subnameTextColor;
  final Color dividerColor;
  final Color backgroundColor;
  final Color iconColor;
  final Color settingActionsIconColor;
  final Color settingTitleColor;

  CakeMenuTheme(
      {required this.headerFirstGradientColor,
      required this.headerSecondGradientColor,
      required this.backgroundColor,
      required this.subnameTextColor,
      required this.dividerColor,
      required this.iconColor,
      required this.settingActionsIconColor,
      required this.settingTitleColor});

  @override
  CakeMenuTheme copyWith(
          {Color? headerFirstGradientColor,
          Color? headerSecondGradientColor,
          Color? backgroundColor,
          Color? subnameTextColor,
          Color? dividerColor,
          Color? iconColor,
          Color? settingActionsIconColor,
          Color? settingTitleColor}) =>
      CakeMenuTheme(
          headerFirstGradientColor:
              headerFirstGradientColor ?? this.headerFirstGradientColor,
          headerSecondGradientColor:
              headerSecondGradientColor ?? this.headerSecondGradientColor,
          backgroundColor: backgroundColor ?? this.backgroundColor,
          subnameTextColor: subnameTextColor ?? this.subnameTextColor,
          dividerColor: dividerColor ?? this.dividerColor,
          iconColor: iconColor ?? this.iconColor,
          settingActionsIconColor:
              settingActionsIconColor ?? this.settingActionsIconColor,
          settingTitleColor: settingTitleColor ?? this.settingTitleColor);

  @override
  CakeMenuTheme lerp(ThemeExtension<CakeMenuTheme>? other, double t) {
    if (other is! CakeMenuTheme) {
      return this;
    }

    return CakeMenuTheme(
        headerFirstGradientColor: Color.lerp(
                headerFirstGradientColor, other.headerFirstGradientColor, t) ??
            headerFirstGradientColor,
        headerSecondGradientColor: Color.lerp(headerSecondGradientColor,
                other.headerSecondGradientColor, t) ??
            headerSecondGradientColor,
        backgroundColor:
            Color.lerp(backgroundColor, other.backgroundColor, t) ??
                backgroundColor,
        subnameTextColor:
            Color.lerp(subnameTextColor, other.subnameTextColor, t) ??
                subnameTextColor,
        dividerColor:
            Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor,
        iconColor: Color.lerp(iconColor, other.iconColor, t) ?? iconColor,
        settingActionsIconColor: Color.lerp(
                settingActionsIconColor, other.settingActionsIconColor, t) ??
            settingActionsIconColor, 
        settingTitleColor: Color.lerp(
                settingTitleColor, other.settingTitleColor, t) ??
            settingTitleColor);
  }
}
