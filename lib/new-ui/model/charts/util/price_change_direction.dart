import "package:flutter/material.dart";

class PriceChangeDirection {

  const PriceChangeDirection._(this.lightColor, this.darkColor, this.symbol);
  final Color lightColor;
  final Color darkColor;
  final String symbol;

  Color colorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkColor : lightColor;

  static const up = PriceChangeDirection._(Color(0xFF00C317), Color(0xFF6FC84E), "+");
  static const down = PriceChangeDirection._(Color(0xFFF9434C), Color(0xFFEA696F), "-");
}
