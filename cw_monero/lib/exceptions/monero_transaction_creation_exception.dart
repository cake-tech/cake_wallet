import "package:cw_core/exceptions/cake_exception.dart";

class MoneroTransactionCreationException extends TransactionGenerationException {
  const MoneroTransactionCreationException(super.message);
}
