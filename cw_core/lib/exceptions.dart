import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';

class TransactionWrongBalanceException implements Exception {
  TransactionWrongBalanceException(this.currency,
      {this.amount, this.requiredBalance, this.availableBalance, this.fee, this.feePriority});

  final CryptoCurrency currency;
  final int? amount;

  /// Exact funding requirement and spendable balance in [currency].
  final Money? requiredBalance;
  final Money? availableBalance;

  /// Maximum fee budget, not a realized charge or token principal.
  final Money? fee;
  final TransactionPriority? feePriority;
}

class TransactionNoInputsException implements Exception {}

class TransactionNoFeeException implements Exception {}

class TransactionNoDustException implements Exception {}

class TransactionNoDustOnChangeException implements Exception {
  TransactionNoDustOnChangeException(this.max, this.min);

  final String max;
  final String min;
}

class TransactionCommitFailed implements Exception {
  final String? errorMessage;

  TransactionCommitFailed({this.errorMessage});

  @override
  String toString() => errorMessage ?? "unknown error";
}

class TransactionCommitFailedDustChange implements Exception {}

class TransactionCommitFailedDustOutput implements Exception {}

class TransactionCommitFailedDustOutputSendAll implements Exception {}

class TransactionCommitFailedVoutNegative implements Exception {}

class TransactionCommitFailedBIP68Final implements Exception {}

class TransactionCommitFailedLessThanMin implements Exception {}

class TransactionInputNotSupported implements Exception {}

class SignNativeTokenTransactionRentException implements Exception {}

class CreateAssociatedTokenAccountException implements Exception {
  final String errorMessage;

  CreateAssociatedTokenAccountException(this.errorMessage);
}

class SignSPLTokenTransactionRentException implements Exception {}

class NoAssociatedTokenAccountException implements Exception {}

class AmbiguousTokenSymbolException implements Exception {
  AmbiguousTokenSymbolException(this.symbol);

  final String symbol;
}

class RestoreFromSeedException implements Exception {
  final String message;

  RestoreFromSeedException(this.message);
}

class WalletDeprecationException implements Exception {
  final String seed;
  final CryptoCurrency curr;

  @override
  String toString() => "Wallet type no longer supported";

  WalletDeprecationException({required this.seed, required this.curr});
}

class WalletSwitchException implements Exception {
  WalletSwitchException(this.message);

  final String message;

  @override
  String toString() => message;
}
