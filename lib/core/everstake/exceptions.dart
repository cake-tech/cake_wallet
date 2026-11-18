import "package:cw_core/amount/money.dart";
import "package:cw_core/exceptions/cake_exception.dart";

class EverstakeResponseException extends ServerResponseException with ResponseCodeException {
  const EverstakeResponseException(super.message, this.code);

  @override
  final int code;
}

class EverstakeNonPositiveAmountException extends TransactionGenerationException {
  const EverstakeNonPositiveAmountException() : super("Amount must be greater than zero");
}

class EverstakeBelowMinimumException extends TransactionGenerationException {
  const EverstakeBelowMinimumException() : super("Amount is below the minimum stake");
}

class EverstakeInsufficientBalanceException extends TransactionGenerationException {
  const EverstakeInsufficientBalanceException() : super("Amount exceeds the available balance");
}

class EverstakeRemainderBelowMinimumException extends TransactionGenerationException {
  const EverstakeRemainderBelowMinimumException(this.minimum)
      : super("Remaining pending stake is below the minimum");

  final Money minimum;
}

class EverstakeWithdrawalNotReadyException extends TransactionGenerationException {
  const EverstakeWithdrawalNotReadyException() : super("No withdrawal is ready to claim");
}

class EverstakeMainnetRequiredException extends BadChainIdException {
  const EverstakeMainnetRequiredException() : super("Everstake staking requires Ethereum mainnet");
}
