import 'package:cake_wallet/src/domain/common/crypto_amount_format.dart';
import 'package:intl/intl.dart';

const bitcoinAmountDivider = 100000000;
const bitcoinAmountLength = 12;
final bitcoinAmountFormat = NumberFormat()
  ..maximumFractionDigits = bitcoinAmountLength
  ..minimumFractionDigits = 1;

String bitcoinAmountToString({int amount}) =>
    bitcoinAmountFormat.format(cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider));

double bitcoinAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider);