import 'package:flutter/material.dart';

class TransactionTradeTheme extends ThemeExtension<TransactionTradeTheme> {
  final Color detailsTitlesColor;
  final Color rowsColor;

  TransactionTradeTheme(
      {required this.detailsTitlesColor, required this.rowsColor});

  @override
  TransactionTradeTheme copyWith(
          {Color? detailsTitlesColor, Color? rowsColor}) =>
      TransactionTradeTheme(
          detailsTitlesColor: detailsTitlesColor ?? this.detailsTitlesColor,
          rowsColor: rowsColor ?? this.rowsColor);

  @override
  TransactionTradeTheme lerp(
      ThemeExtension<TransactionTradeTheme>? other, double t) {
    if (other is! TransactionTradeTheme) {
      return this;
    }

    return TransactionTradeTheme(
        detailsTitlesColor:
            Color.lerp(detailsTitlesColor, other.detailsTitlesColor, t)!,
        rowsColor: Color.lerp(rowsColor, other.rowsColor, t)!);
  }
}
