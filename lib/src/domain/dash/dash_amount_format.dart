import 'package:cake_wallet/src/domain/common/crypto_amount_format.dart';

const dashAmountDivider = 100000000;

double dashAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: dashAmountDivider);