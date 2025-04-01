import 'package:cw_core/crypto_currency.dart';

class EVMChainTransactionCreationException implements Exception {
  final String exceptionMessage;

  EVMChainTransactionCreationException(CryptoCurrency currency)
      : exceptionMessage = 'Wrong balance. Not enough ${currency.title} on your balance.';

  EVMChainTransactionCreationException.fromMessage(this.exceptionMessage);

  @override
  String toString() => exceptionMessage;
}


class EVMChainTransactionFeesException implements Exception {
  final String exceptionMessage;

  EVMChainTransactionFeesException(String currency)
      : exceptionMessage = 'Transaction failed due to insufficient $currency balance to cover the fees.';

  @override
  String toString() => exceptionMessage;
}
