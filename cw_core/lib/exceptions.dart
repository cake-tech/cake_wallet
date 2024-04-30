import 'package:cw_core/crypto_currency.dart';

class TransactionWrongBalanceException implements Exception {
  TransactionWrongBalanceException(this.currency);

  final CryptoCurrency currency;
}

class TransactionNoInputsException implements Exception {}

class TransactionNoFeeException implements Exception {}

class TransactionNoDustException implements Exception {}

class TransactionNoDustOnChangeException implements Exception {
  TransactionNoDustOnChangeException(this.max, this.min);

  final String max;
  final String min;
}

class TransactionCommitFailed implements Exception {
  final String? errorMessage;

  TransactionCommitFailed({this.errorMessage});
}

class TransactionCommitFailedDustChange implements Exception {}

class TransactionCommitFailedDustOutput implements Exception {}

class TransactionCommitFailedDustOutputSendAll implements Exception {}

class TransactionCommitFailedVoutNegative implements Exception {}
