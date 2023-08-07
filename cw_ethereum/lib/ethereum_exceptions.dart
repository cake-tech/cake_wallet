import 'package:cw_core/crypto_currency.dart';

class EthereumTransactionCreationException implements Exception {
  final String exceptionMessage;

  EthereumTransactionCreationException(CryptoCurrency currency) :
    this.exceptionMessage = 'Wrong balance. Not enough ${currency.title} on your balance.';

  @override
  String toString() => exceptionMessage;
}
