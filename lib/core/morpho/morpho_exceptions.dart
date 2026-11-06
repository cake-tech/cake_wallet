import "package:cw_core/exceptions/cake_exception.dart";

class MorphoApiException extends ServerResponseException {
  const MorphoApiException(super.message);
}

class MorphoNonPositiveAmountException extends TransactionGenerationException {
  const MorphoNonPositiveAmountException() : super("Amount must be greater than zero");
}

class MorphoInsufficientBalanceException extends TransactionGenerationException {
  const MorphoInsufficientBalanceException() : super("Amount exceeds the available balance");
}

class MorphoExceedsWithdrawableException extends TransactionGenerationException {
  const MorphoExceedsWithdrawableException()
      : super("Amount exceeds what the vault can pay out now");
}

class MorphoMainnetRequiredException extends BadChainIdException {
  const MorphoMainnetRequiredException() : super("Morpho requires Ethereum mainnet");
}

class MorphoTransactionFailedException extends TransactionSendingException {
  const MorphoTransactionFailedException() : super("Transaction reverted");
}
