import 'dart:ui';

class PriceChangeDirection {
  final Color color;
  final String symbol;

  const PriceChangeDirection._(this.color, this.symbol);

  static const up = PriceChangeDirection._(Color(0xFF6FC84E), "+");
  static const down = PriceChangeDirection._(Color(0xFFEA696F), "-");
}