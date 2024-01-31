import 'package:cw_core/crypto_currency.dart';

class EVMChainTransactionCreationException implements Exception {
  final String exceptionMessage;

  EVMChainTransactionCreationException(CryptoCurrency currency)
      : exceptionMessage = 'Wrong balance. Not enough ${currency.title} on your balance.';

  @override
  String toString() => exceptionMessage;
}
