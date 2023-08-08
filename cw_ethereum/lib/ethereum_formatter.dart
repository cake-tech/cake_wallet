import 'package:intl/intl.dart';

const ethereumAmountLength = 12;
const ethereumAmountDivider = 1000000000000;
final ethereumAmountFormat = NumberFormat()
  ..maximumFractionDigits = ethereumAmountLength
  ..minimumFractionDigits = 1;

class EthereumFormatter {
  static int parseEthereumAmount(String amount) {
    try {
      return (double.parse(amount) * ethereumAmountDivider).round();
    } catch (_) {
      return 0;
    }
  }

  static double parseEthereumAmountToDouble(int amount) {
    try {
      return amount / ethereumAmountDivider;
    } catch (_) {
      return 0;
    }
  }
}
