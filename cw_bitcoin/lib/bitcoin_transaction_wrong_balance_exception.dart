import 'package:cw_core/crypto_currency.dart';

class BitcoinTransactionWrongBalanceException implements Exception {
  BitcoinTransactionWrongBalanceException(this.currency);

  final CryptoCurrency currency;

  @override
  String toString() => 'Wrong balance. Not enough ${currency.title} on your balance.';
}