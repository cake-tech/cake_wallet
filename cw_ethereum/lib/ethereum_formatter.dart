import 'dart:math';

class EthereumFormatter {
  static int parseEthereumAmount(String amount) =>
      BigInt.from(double.parse(amount) * (pow(10, 18))).toInt();
}
