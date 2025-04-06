import 'package:cw_core/crypto_currency.dart';

class XelisMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      'Xelis mnemonic has incorrect format. Mnemonic should contain 25 words separated by space.';
}
class XelisTransactionCreationException implements Exception {
  final String exceptionMessage;

  XelisTransactionCreationException(CryptoCurrency currency)
      : exceptionMessage = 'Wrong balance. Not enough ${currency.title} on your balance.';

  @override
  String toString() => exceptionMessage;
}