import 'package:cake_wallet/src/domain/common/crypto_amount_format.dart';

const bitcoinCashAmountDivider = 100000000;

double bitcoinCashAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: bitcoinCashAmountDivider);