import 'package:flutter/material.dart';

class SendPageTheme extends ThemeExtension<SendPageTheme> {
  final Color templateTitleColor;
  final Color templateBackgroundColor;
  final Color templateNewTextColor;
  final Color templateDottedBorderColor;
  final Color estimatedFeeColor;
  final Color textFieldButtonIconColor;
  final Color textFieldButtonColor;
  final Color textFieldHintColor;
  final Color textFieldBorderColor;
  final Color firstGradientColor;
  final Color secondGradientColor;

  SendPageTheme(
      {required this.templateTitleColor,
      required this.templateBackgroundColor,
      required this.templateNewTextColor,
      required this.templateDottedBorderColor,
      required this.estimatedFeeColor,
      required this.textFieldButtonIconColor,
      required this.textFieldButtonColor,
      required this.textFieldHintColor,
      required this.textFieldBorderColor,
      required this.firstGradientColor,
      required this.secondGradientColor});

  @override
  SendPageTheme copyWith(
          {Color? templateTitleColor,
          Color? templateBackgroundColor,
          Color? templateNewTextColor,
          Color? templateDotterBorderColor,
          Color? estimatedFeeColor,
          Color? textFieldButtonIconColor,
          Color? textFieldButtonColor,
          Color? textFieldHintColor,
          Color? textFieldBorderColor,
          Color? firstGradientColor,
          Color? secondGradientColor}) =>
      SendPageTheme(
          templateTitleColor: templateTitleColor ?? this.templateTitleColor,
          templateBackgroundColor:
              templateBackgroundColor ?? this.templateBackgroundColor,
          templateNewTextColor:
              templateNewTextColor ?? this.templateNewTextColor,
          templateDottedBorderColor:
              templateDotterBorderColor ?? this.templateDottedBorderColor,
          estimatedFeeColor: estimatedFeeColor ?? this.estimatedFeeColor,
          textFieldButtonIconColor:
              textFieldButtonIconColor ?? this.textFieldButtonIconColor,
          textFieldButtonColor:
              textFieldButtonColor ?? this.textFieldButtonColor,
          textFieldHintColor: textFieldHintColor ?? this.textFieldHintColor,
          textFieldBorderColor:
              textFieldBorderColor ?? this.textFieldBorderColor,
          firstGradientColor: firstGradientColor ?? this.firstGradientColor,
          secondGradientColor: secondGradientColor ?? this.secondGradientColor);

  @override
  SendPageTheme lerp(ThemeExtension<SendPageTheme>? other, double t) {
    if (other is! SendPageTheme) {
      return this;
    }

    return SendPageTheme(
        templateTitleColor: Color.lerp(
            templateTitleColor, other.templateTitleColor, t)!,
        templateBackgroundColor: Color.lerp(
            templateBackgroundColor, other.templateBackgroundColor, t)!,
        templateNewTextColor:
            Color.lerp(templateNewTextColor, other.templateNewTextColor, t)!,
        templateDottedBorderColor: Color.lerp(
            templateDottedBorderColor,
            other.templateDottedBorderColor,
            t)!,
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
            Color.lerp(secondGradientColor, other.secondGradientColor, t)!);
  }
}
