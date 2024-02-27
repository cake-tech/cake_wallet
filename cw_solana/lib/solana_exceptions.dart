import 'package:cw_core/crypto_currency.dart';

class SolanaTransactionCreationException implements Exception {
  final String exceptionMessage;

  SolanaTransactionCreationException(CryptoCurrency currency)
      : exceptionMessage = 'Error creating ${currency.title} transaction.';

  @override
  String toString() => exceptionMessage;
}

class SolanaTransactionWrongBalanceException implements Exception {
  final String exceptionMessage;

  SolanaTransactionWrongBalanceException(CryptoCurrency currency)
      : exceptionMessage = 'Wrong balance. Not enough ${currency.title} on your balance.';

  @override
  String toString() => exceptionMessage;
}
