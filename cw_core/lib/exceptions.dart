import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/exceptions/cake_exception.dart";

class TransactionWrongBalanceException extends TransactionGenerationException {
  TransactionWrongBalanceException(this.currency, {this.amount}) : super( "wrong balance: ${currency.symbol} $amount");


  final CryptoCurrency currency;
  final int? amount;
}

class TransactionNoInputsException extends TransactionGenerationException {

  TransactionNoInputsException() : super("Not enough inputs available. Please select more under Coin Control");

}
class TransactionNoFeeException extends TransactionGenerationException {
  TransactionNoFeeException() : super("cannot send with zero fee");
}

class TransactionNoDustException extends TransactionGenerationException {
  TransactionNoDustException()
      : super("The transaction is rejected by sending an amount too small. Please try increasing the amount.");
}

class TransactionNoDustOnChangeException extends TransactionGenerationException {
  final String max;
  final String min;

  TransactionNoDustOnChangeException(this.max, this.min)
      : super("The transaction is rejected with this amount. With these coins you can send ${min} without change or ${max} that returns change.");
}

class TransactionCommitFailed extends TransactionSendingException {
  final String? errorMessage;

  TransactionCommitFailed({this.errorMessage}) : super(errorMessage ?? "unknown error");
}

class TransactionCommitFailedDustChange extends TransactionSendingException {
  TransactionCommitFailedDustChange()
      : super("Transaction rejected by network rules, low change amount (dust). Try sending ALL or reducing the amount.");
}

class TransactionCommitFailedDustOutput extends TransactionSendingException {
  TransactionCommitFailedDustOutput()
      : super("Transaction rejected by network rules, low output amount (dust). Please increase the amount.");
}

class TransactionCommitFailedDustOutputSendAll extends TransactionSendingException {
  TransactionCommitFailedDustOutputSendAll()
      : super("Transaction rejected by network rules, low output amount (dust). Please check the balance of coins selected under Coin Control.");
}

class TransactionCommitFailedVoutNegative extends TransactionSendingException {
  TransactionCommitFailedVoutNegative()
      : super("Not enough balance to pay for this transaction's fees. Please check the balance of coins under Coin Control.");
}

class TransactionCommitFailedBIP68Final extends TransactionSendingException {
  TransactionCommitFailedBIP68Final()
      : super("Transaction has unconfirmed inputs and failed to replace by fee.");
}

class TransactionCommitFailedLessThanMin extends TransactionSendingException {
  TransactionCommitFailedLessThanMin()
      : super("Selected Fee is less than the minimum, please increase the fees to be able to send the transaction");
}

class TransactionInputNotSupported extends TransactionSendingException {
  TransactionInputNotSupported()
      : super("You are using the wrong input type for this type of payment");
}

class SignNativeTokenTransactionRentException extends TransactionGenerationException {
  SignNativeTokenTransactionRentException()
      : super("Transaction cannot be completed. Insufficient SOL left for rent after transaction. Kindly top up your SOL balance or reduce the amount of SOL you are sending.");
}

class CreateAssociatedTokenAccountException extends CakeException {
  final String errorMessage;

  CreateAssociatedTokenAccountException(this.errorMessage)
      : super("Error creating associated token account for receipient address. " + errorMessage);
}

class SignSPLTokenTransactionRentException extends CakeException {
  SignSPLTokenTransactionRentException()
      : super("Transaction cannot be completed. Insufficient SOL left for rent after transaction. Kindly top up your SOL balance.");
}

class NoAssociatedTokenAccountException extends CakeException {
  NoAssociatedTokenAccountException()
      : super("There is no associated token account for this address.");
}

class RestoreFromSeedException extends CakeException {
  RestoreFromSeedException(String message) : super(message);
}

class WalletDeprecationException extends CakeException {
  final String seed;
  final CryptoCurrency curr;

  WalletDeprecationException({required this.seed, required this.curr})
      : super("Wallet type no longer supported");
}
