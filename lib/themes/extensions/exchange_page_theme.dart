import 'package:flutter/material.dart';

class ExchangePageTheme extends ThemeExtension<ExchangePageTheme> {
  final Color hintTextColor;
  final Color receiveAmountColor;
  final Color firstGradientTopPanelColor;
  final Color secondGradientTopPanelColor;
  final Color firstGradientBottomPanelColor;
  final Color secondGradientBottomPanelColor;
  final Color textFieldBorderTopPanelColor;
  final Color textFieldBorderBottomPanelColor;
  final Color textFieldButtonColor;
  final Color buttonBackgroundColor;
  final Color qrCodeColor;
  final Color dividerCodeColor;

  ExchangePageTheme(
      {required this.hintTextColor,
      required this.receiveAmountColor,
      required this.firstGradientTopPanelColor,
      required this.secondGradientTopPanelColor,
      required this.firstGradientBottomPanelColor,
      required this.secondGradientBottomPanelColor,
      required this.textFieldBorderTopPanelColor,
      required this.textFieldBorderBottomPanelColor,
      required this.textFieldButtonColor,
      required this.buttonBackgroundColor,
      required this.qrCodeColor,
      required this.dividerCodeColor});

  @override
  ExchangePageTheme copyWith({
    Color? hintTextColor,
    Color? receiveAmountColor,
    Color? firstGradientTopPanelColor,
    Color? secondGradientTopPanelColor,
    Color? firstGradientBottomPanelColor,
    Color? secondGradientBottomPanelColor,
    Color? textFieldBorderTopPanelColor,
    Color? textFieldBorderBottomPanelColor,
    Color? textFieldButtonColor,
    Color? buttonBackgroundColor,
    Color? qrCodeColor,
    Color? dividerCodeColor,
  }) =>
      ExchangePageTheme(
          hintTextColor: hintTextColor ?? this.hintTextColor,
          receiveAmountColor: receiveAmountColor ?? this.receiveAmountColor,
          firstGradientTopPanelColor:
              firstGradientTopPanelColor ?? this.firstGradientTopPanelColor,
          secondGradientTopPanelColor:
              secondGradientTopPanelColor ?? this.secondGradientTopPanelColor,
          firstGradientBottomPanelColor: firstGradientBottomPanelColor ??
              this.firstGradientBottomPanelColor,
          secondGradientBottomPanelColor: secondGradientBottomPanelColor ??
              this.secondGradientBottomPanelColor,
          textFieldBorderTopPanelColor:
              textFieldBorderTopPanelColor ?? this.textFieldBorderTopPanelColor,
          textFieldBorderBottomPanelColor: textFieldBorderBottomPanelColor ??
              this.textFieldBorderBottomPanelColor,
          textFieldButtonColor:
              textFieldButtonColor ?? this.textFieldButtonColor,
          buttonBackgroundColor:
              buttonBackgroundColor ?? this.buttonBackgroundColor,
          qrCodeColor: qrCodeColor ?? this.qrCodeColor,
          dividerCodeColor: dividerCodeColor ?? this.dividerCodeColor);

  @override
  ExchangePageTheme lerp(ThemeExtension<ExchangePageTheme>? other, double t) {
    if (other is! ExchangePageTheme) {
      return this;
    }

    return ExchangePageTheme(
        hintTextColor: Color.lerp(hintTextColor, other.hintTextColor, t) ?? hintTextColor,
        receiveAmountColor: Color.lerp(receiveAmountColor, other.receiveAmountColor, t) ?? receiveAmountColor,
        firstGradientTopPanelColor: Color.lerp(firstGradientTopPanelColor, other.firstGradientTopPanelColor, t) ?? firstGradientTopPanelColor,
        secondGradientTopPanelColor: Color.lerp(secondGradientTopPanelColor, other.secondGradientTopPanelColor, t) ?? secondGradientTopPanelColor,
        firstGradientBottomPanelColor: Color.lerp(firstGradientBottomPanelColor, other.firstGradientBottomPanelColor, t) ?? firstGradientBottomPanelColor,
        secondGradientBottomPanelColor: Color.lerp(secondGradientBottomPanelColor, other.secondGradientBottomPanelColor, t) ?? secondGradientBottomPanelColor,
        textFieldBorderTopPanelColor: Color.lerp(textFieldBorderTopPanelColor, other.textFieldBorderTopPanelColor, t) ?? textFieldBorderTopPanelColor,
        textFieldBorderBottomPanelColor: Color.lerp(textFieldBorderBottomPanelColor, other.textFieldBorderBottomPanelColor, t) ?? textFieldBorderBottomPanelColor,
        textFieldButtonColor: Color.lerp(textFieldButtonColor, other.textFieldButtonColor, t) ?? textFieldButtonColor,
        buttonBackgroundColor: Color.lerp(buttonBackgroundColor, other.buttonBackgroundColor, t) ?? buttonBackgroundColor,
        qrCodeColor: Color.lerp(qrCodeColor, other.qrCodeColor, t) ?? qrCodeColor,
        dividerCodeColor: Color.lerp(dividerCodeColor, other.dividerCodeColor, t) ?? dividerCodeColor);
  }
}
