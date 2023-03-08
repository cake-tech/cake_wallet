import 'package:intl/intl.dart';
import 'package:cw_core/crypto_amount_format.dart';

const bitcoinAmountLength = 8;
const bitcoinAmountDivider = 100000000;
final bitcoinAmountFormat = NumberFormat()
  ..maximumFractionDigits = bitcoinAmountLength
  ..minimumFractionDigits = 1;

String bitcoinAmountToString({required int amount}) => bitcoinAmountFormat.format(
    cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider));

double bitcoinAmountToDouble({required int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider);

int stringDoubleToBitcoinAmount(String amount) {
  int result = 0;

  try {
    result = (double.parse(amount) * bitcoinAmountDivider).round();
  } catch (e) {
    result = 0;
  }

  return result;
}
