import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/exceptions.dart';

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

class SolanaSignNativeTokenTransactionRentException
    extends SignNativeTokenTransactionRentException {}

class SolanaCreateAssociatedTokenAccountException extends CreateAssociatedTokenAccountException {
  SolanaCreateAssociatedTokenAccountException(super.errorMessage);
}

class SolanaSignSPLTokenTransactionRentException extends SignSPLTokenTransactionRentException {}

class SolanaNoAssociatedTokenAccountException extends NoAssociatedTokenAccountException {
  SolanaNoAssociatedTokenAccountException(this.account, this.mint);

  final String account;
  final String mint;
}
