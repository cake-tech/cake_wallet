import 'package:flutter/material.dart';

class BalancePageTheme extends ThemeExtension<BalancePageTheme> {
  final Color textColor;
  final Color labelTextColor;
  final Color balanceAmountColor;
  final Color assetTitleColor;
  final Color cardBorderColor;

  BalancePageTheme(
      {required this.labelTextColor,
      required this.textColor,
      Color? balanceAmountColor,
      Color? assetTitleColor,
      this.cardBorderColor = Colors.transparent})
      : this.balanceAmountColor = balanceAmountColor ?? textColor,
        this.assetTitleColor = assetTitleColor ?? textColor;

  @override
  BalancePageTheme copyWith(
          {Color? textColor,
          Color? labelTextColor,
          Color? balanceAmountColor,
          Color? assetTitleColor,
          Color? cardBorderColor}) =>
      BalancePageTheme(
          textColor: textColor ?? this.textColor,
          labelTextColor: labelTextColor ?? this.labelTextColor,
          balanceAmountColor: balanceAmountColor ?? this.balanceAmountColor,
          assetTitleColor: assetTitleColor ?? this.assetTitleColor,
          cardBorderColor: cardBorderColor ?? this.cardBorderColor);

  @override
  BalancePageTheme lerp(ThemeExtension<BalancePageTheme>? other, double t) {
    if (other is! BalancePageTheme) {
      return this;
    }

    return BalancePageTheme(
        textColor: Color.lerp(textColor, other.textColor, t) ?? textColor,
        labelTextColor: Color.lerp(labelTextColor, other.labelTextColor, t) ??
            labelTextColor,
        balanceAmountColor:
            Color.lerp(balanceAmountColor, other.balanceAmountColor, t) ??
                balanceAmountColor,
        assetTitleColor:
            Color.lerp(assetTitleColor, other.assetTitleColor, t) ??
                assetTitleColor,
        cardBorderColor:
            Color.lerp(cardBorderColor, other.cardBorderColor, t) ??
                cardBorderColor);
  }
}
