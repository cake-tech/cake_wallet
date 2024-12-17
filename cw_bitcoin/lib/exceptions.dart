import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/exceptions.dart';

class BitcoinTransactionWrongBalanceException extends TransactionWrongBalanceException {
  BitcoinTransactionWrongBalanceException({super.amount}) : super(CryptoCurrency.btc);

  @override
  String toString() {
    return "BitcoinTransactionWrongBalanceException: $amount, $currency";
  }
}

class BitcoinTransactionNoInputsException extends TransactionNoInputsException {}

class BitcoinTransactionNoFeeException extends TransactionNoFeeException {}

class BitcoinTransactionNoDustException extends TransactionNoDustException {}

class BitcoinTransactionNoDustOnChangeException extends TransactionNoDustOnChangeException {
  BitcoinTransactionNoDustOnChangeException(super.max, super.min);

  @override
  String toString() {
    return "BitcoinTransactionNoDustOnChangeException: max: $max, min: $min";
  }
}

class BitcoinTransactionCommitFailed extends TransactionCommitFailed {
  BitcoinTransactionCommitFailed({super.errorMessage});

  @override
  String toString() {
    return errorMessage??"unknown error";
  }
}

class BitcoinTransactionCommitFailedDustChange extends TransactionCommitFailedDustChange {}

class BitcoinTransactionCommitFailedDustOutput extends TransactionCommitFailedDustOutput {}

class BitcoinTransactionCommitFailedDustOutputSendAll
    extends TransactionCommitFailedDustOutputSendAll {}

class BitcoinTransactionCommitFailedVoutNegative extends TransactionCommitFailedVoutNegative {}

class BitcoinTransactionCommitFailedBIP68Final extends TransactionCommitFailedBIP68Final {}

class BitcoinTransactionCommitFailedLessThanMin extends TransactionCommitFailedLessThanMin {}

class BitcoinTransactionSilentPaymentsNotSupported extends TransactionInputNotSupported {}
