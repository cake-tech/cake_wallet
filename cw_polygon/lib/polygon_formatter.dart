import 'package:intl/intl.dart';

const polygonAmountLength = 12;
const polygonAmountDivider = 1000000000000;
final polygonAmountFormat = NumberFormat()
  ..maximumFractionDigits = polygonAmountLength
  ..minimumFractionDigits = 1;

class PolygonFormatter {
  static int parsePolygonAmount(String amount) {
    try {
      return (double.parse(amount) * polygonAmountDivider).round();
    } catch (_) {
      return 0;
    }
  }

  static double parsePolygonAmountToDouble(int amount) {
    try {
      return amount / polygonAmountDivider;
    } catch (_) {
      return 0;
    }
  }
}
