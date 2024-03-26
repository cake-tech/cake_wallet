import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/exceptions.dart';

class BitcoinTransactionWrongBalanceException extends TransactionWrongBalanceException {
  BitcoinTransactionWrongBalanceException() : super(CryptoCurrency.btc);
}

class BitcoinTransactionNoInputsException extends TransactionNoInputsException {}

class BitcoinTransactionNoFeeException extends TransactionNoFeeException {}

class BitcoinTransactionNoDustException extends TransactionNoDustException {}

class BitcoinTransactionNoDustOnChangeException extends TransactionNoDustOnChangeException {
  BitcoinTransactionNoDustOnChangeException(super.max, super.min);
}

class BitcoinTransactionCommitFailed extends TransactionCommitFailed {}

class BitcoinTransactionCommitFailedDustChange extends TransactionCommitFailedDustChange {}

class BitcoinTransactionCommitFailedDustOutput extends TransactionCommitFailedDustOutput {}

class BitcoinTransactionCommitFailedDustOutputSendAll
    extends TransactionCommitFailedDustOutputSendAll {}

class BitcoinTransactionCommitFailedVoutNegative extends TransactionCommitFailedVoutNegative {}
