import "package:cw_core/exceptions/cake_exception.dart";

class PayjoinSessionError extends CakeException{
  const PayjoinSessionError._(super.message);

  factory PayjoinSessionError.recoverable(String message) = RecoverableError;
  factory PayjoinSessionError.unrecoverable(String message) = UnrecoverableError;
}

class RecoverableError extends PayjoinSessionError {
  const RecoverableError(super.message) : super._();
}

class UnrecoverableError extends PayjoinSessionError {
  const UnrecoverableError(super.message) : super._();
}
