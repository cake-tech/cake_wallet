import 'package:cw_core/crypto_currency.dart';

class TronMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Tron mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.';
}

class TronTransactionCreationException implements Exception {
  final String exceptionMessage;

  TronTransactionCreationException(CryptoCurrency currency)
      : exceptionMessage = 'Wrong balance. Not enough ${currency.title} on your balance.';

  TronTransactionCreationException.zeroAmount(CryptoCurrency currency)
      : exceptionMessage = 'The ${currency.title} amount must be greater than 0.';

  @override
  String toString() => exceptionMessage;
}
