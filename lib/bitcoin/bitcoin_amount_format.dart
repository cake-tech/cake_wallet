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
  int result = 0;

  try {
    result = (double.parse(amount) * bitcoinAmountDivider).toInt();
  } catch (e) {
    result = 0;
  }

  return result;
}
