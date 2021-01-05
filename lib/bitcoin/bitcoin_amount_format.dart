import 'dart:math';

import 'package:intl/intl.dart';
import 'package:cake_wallet/entities/crypto_amount_format.dart';

const bitcoinAmountLength = 8;
const bitcoinAmountDivider = 100000000;
final bitcoinAmountFormat = NumberFormat()
  ..maximumFractionDigits = bitcoinAmountLength
  ..minimumFractionDigits = 1;

String bitcoinAmountToString({int amount}) => bitcoinAmountFormat.format(
    cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider));

double bitcoinAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider);

int stringDoubleToBitcoinAmount(String amount) {
  final splitted = amount.split('');
  final dotIndex = amount.indexOf('.');
  int result = 0;


  for (var i = 0; i < splitted.length; i++) {
    try {
      if (dotIndex == i) {
        continue;
      }

      final char = splitted[i];
      final multiplier = dotIndex < i
          ? bitcoinAmountDivider ~/ pow(10, (i - dotIndex))
          : (bitcoinAmountDivider * pow(10, (dotIndex - i -1))).toInt();
      final num = int.parse(char) * multiplier;
      result += num;
    } catch (_) {}
  }

  return result;
}
