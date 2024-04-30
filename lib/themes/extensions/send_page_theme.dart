import 'package:flutter/material.dart';

class SendPageTheme extends ThemeExtension<SendPageTheme> {
  final Color templateTitleColor;
  final Color templateBackgroundColor;
  final Color templateNewTextColor;
  final Color templateSelectedCurrencyBackgroundColor;
  final Color templateSelectedCurrencyTitleColor;
  final Color templateDottedBorderColor;
  final Color estimatedFeeColor;
  final Color textFieldButtonIconColor;
  final Color textFieldButtonColor;
  final Color textFieldHintColor;
  final Color textFieldBorderColor;
  final Color firstGradientColor;
  final Color secondGradientColor;
  final Color indicatorDotColor;

  SendPageTheme(
      {required this.templateTitleColor,
      required this.templateBackgroundColor,
      required this.templateNewTextColor,
      required this.templateSelectedCurrencyBackgroundColor,
      required this.templateSelectedCurrencyTitleColor,
      required this.templateDottedBorderColor,
      required this.estimatedFeeColor,
      required this.textFieldButtonIconColor,
      required this.textFieldButtonColor,
      required this.textFieldHintColor,
      required this.textFieldBorderColor,
      required this.firstGradientColor,
      required this.secondGradientColor,
      required this.indicatorDotColor});

  @override
  SendPageTheme copyWith(
          {Color? templateTitleColor,
          Color? templateBackgroundColor,
          Color? templateNewTextColor,
          Color? templateSelectedCurrencyBackgroundColor,
          Color? templateSelectedCurrencyTitleColor,
          Color? templateDottedBorderColor,
          Color? estimatedFeeColor,
          Color? textFieldButtonIconColor,
          Color? textFieldButtonColor,
          Color? textFieldHintColor,
          Color? textFieldBorderColor,
          Color? firstGradientColor,
          Color? secondGradientColor,
          Color? indicatorDotColor}) =>
      SendPageTheme(
          templateTitleColor: templateTitleColor ?? this.templateTitleColor,
          templateBackgroundColor:
              templateBackgroundColor ?? this.templateBackgroundColor,
          templateNewTextColor:
              templateNewTextColor ?? this.templateNewTextColor,
          templateSelectedCurrencyBackgroundColor:
              templateSelectedCurrencyBackgroundColor ??
                  this.templateSelectedCurrencyBackgroundColor,
          templateSelectedCurrencyTitleColor:
              templateSelectedCurrencyTitleColor ??
                  this.templateSelectedCurrencyTitleColor,
          templateDottedBorderColor:
              templateDottedBorderColor ?? this.templateDottedBorderColor,
          estimatedFeeColor: estimatedFeeColor ?? this.estimatedFeeColor,
          textFieldButtonIconColor:
              textFieldButtonIconColor ?? this.textFieldButtonIconColor,
          textFieldButtonColor:
              textFieldButtonColor ?? this.textFieldButtonColor,
          textFieldHintColor: textFieldHintColor ?? this.textFieldHintColor,
          textFieldBorderColor:
              textFieldBorderColor ?? this.textFieldBorderColor,
          firstGradientColor: firstGradientColor ?? this.firstGradientColor,
          secondGradientColor: secondGradientColor ?? this.secondGradientColor,
          indicatorDotColor: indicatorDotColor ?? this.indicatorDotColor);

  @override
  SendPageTheme lerp(ThemeExtension<SendPageTheme>? other, double t) {
    if (other is! SendPageTheme) {
      return this;
    }

    return SendPageTheme(
        templateTitleColor:
            Color.lerp(templateTitleColor, other.templateTitleColor, t)!,
        templateBackgroundColor: Color.lerp(
            templateBackgroundColor, other.templateBackgroundColor, t)!,
        templateNewTextColor:
            Color.lerp(templateNewTextColor, other.templateNewTextColor, t)!,
        templateSelectedCurrencyBackgroundColor: Color.lerp(
            templateSelectedCurrencyBackgroundColor,
            other.templateSelectedCurrencyBackgroundColor,
            t)!,
        templateSelectedCurrencyTitleColor: Color.lerp(
            templateSelectedCurrencyTitleColor,
            other.templateSelectedCurrencyTitleColor,
            t)!,
        templateDottedBorderColor: Color.lerp(
            templateDottedBorderColor, other.templateDottedBorderColor, t)!,
        estimatedFeeColor:
            Color.lerp(estimatedFeeColor, other.estimatedFeeColor, t)!,
        textFieldButtonIconColor: Color.lerp(
            textFieldButtonIconColor, other.textFieldButtonIconColor, t)!,
        textFieldButtonColor:
            Color.lerp(textFieldButtonColor, other.textFieldButtonColor, t)!,
        textFieldHintColor:
            Color.lerp(textFieldHintColor, other.textFieldHintColor, t)!,
        textFieldBorderColor:
            Color.lerp(textFieldBorderColor, other.textFieldBorderColor, t)!,
        firstGradientColor:
            Color.lerp(firstGradientColor, other.firstGradientColor, t)!,
        secondGradientColor:
            Color.lerp(secondGradientColor, other.secondGradientColor, t)!,
        indicatorDotColor:
            Color.lerp(indicatorDotColor, other.indicatorDotColor, t)!);
  }
}
