import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/exceptions/cake_exception.dart";

class TransactionWrongBalanceException implements TransactionGenerationException {
  TransactionWrongBalanceException(this.currency, {this.amount});

  @override
  String get message => "wrong balance: ${currency.symbol} $amount";

  final CryptoCurrency currency;
  final int? amount;
}

class TransactionNoInputsException implements TransactionGenerationException {

  @override
  String get message => "Not enough inputs available. Please select more under Coin Control";
}

class TransactionNoFeeException implements TransactionGenerationException {
  @override
  String get message => "cannot send with zero fee";
}

class TransactionNoDustException implements TransactionGenerationException {

  @override
  String get message =>
      "The transaction is rejected by sending an amount too small. Please try increasing the amount.";
}

class TransactionNoDustOnChangeException implements TransactionGenerationException {
  TransactionNoDustOnChangeException(this.max, this.min);

  final String max;
  final String min;

  @override
  String get message =>
      "The transaction is rejected with this amount. With these coins you can send ${min} without change or ${max} that returns change.";
}

class TransactionCommitFailed implements TransactionSendingException {
  final String? errorMessage;

  TransactionCommitFailed({this.errorMessage});

  @override
  String get message => errorMessage ?? "unknown error";

}

class TransactionCommitFailedDustChange implements TransactionSendingException {
  @override
  String get message =>
      "Transaction rejected by network rules, low change amount (dust). Try sending ALL or reducing the amount.";
}

class TransactionCommitFailedDustOutput implements TransactionSendingException {

  @override
  String get message =>
      "Transaction rejected by network rules, low output amount (dust). Please increase the amount.";
}

class TransactionCommitFailedDustOutputSendAll implements TransactionSendingException {
  @override
  String get message =>
      "Transaction rejected by network rules, low output amount (dust). Please check the balance of coins selected under Coin Control.";
}

class TransactionCommitFailedVoutNegative implements TransactionSendingException {
  @override
  String get message =>
      "Not enough balance to pay for this transaction's fees. Please check the balance of coins under Coin Control.";
}

class TransactionCommitFailedBIP68Final implements TransactionSendingException {
  @override
  String get message => "Transaction has unconfirmed inputs and failed to replace by fee.";
}

class TransactionCommitFailedLessThanMin implements TransactionSendingException {
  @override
  String get message =>
      "Selected Fee is less than the minimum, please increase the fees to be able to send the transaction";
}

class TransactionInputNotSupported implements TransactionSendingException {
  @override
  String get message => "You are using the wrong input type for this type of payment";
}

class SignNativeTokenTransactionRentException implements TransactionGenerationException {
  @override
  String get message =>
      "Transaction cannot be completed. Insufficient SOL left for rent after transaction. Kindly top up your SOL balance or reduce the amount of SOL you are sending.";
}

class CreateAssociatedTokenAccountException implements CakeException {
  final String errorMessage;

  CreateAssociatedTokenAccountException(this.errorMessage);

  @override
  String get message =>
      "Error creating associated token account for receipient address. " + errorMessage;
}

class SignSPLTokenTransactionRentException implements CakeException {
  @override
  String get message =>
      "Transaction cannot be completed. Insufficient SOL left for rent after transaction. Kindly top up your SOL balance.";
}

class NoAssociatedTokenAccountException implements CakeException {
  @override
  String get message => "There is no associated token account for this address.";
}

class RestoreFromSeedException implements CakeException {
  final String message;

  RestoreFromSeedException(this.message);
}

class WalletDeprecationException implements CakeException {
  final String seed;
  final CryptoCurrency curr;

  @override
  String get message => "Wallet type no longer supported";

  WalletDeprecationException({required this.seed, required this.curr});
}
