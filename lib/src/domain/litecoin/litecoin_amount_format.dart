import 'package:cake_wallet/src/domain/common/crypto_amount_format.dart';

const litecoinAmountDivider = 100000000;

double litecoinAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: litecoinAmountDivider);