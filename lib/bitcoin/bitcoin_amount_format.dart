import 'package:intl/intl.dart';
import 'package:cake_wallet/src/domain/common/crypto_amount_format.dart';

const bitcoinAmountLength = 8;
const bitcoinAmountDivider = 100000000;
final bitcoinAmountFormat = NumberFormat()
  ..maximumFractionDigits = bitcoinAmountLength
  ..minimumFractionDigits = 1;

String bitcoinAmountToString({int amount}) =>
    bitcoinAmountFormat.format(cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider));

double bitcoinAmountToDouble({int amount}) => cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider);
