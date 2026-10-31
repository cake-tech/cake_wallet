import "package:cw_core/exceptions/cake_exception.dart";

/// Base class for payjoin session errors so typed catches and user-facing
/// [toString] handling follow the shared [CakeException] model.
class PayjoinSessionError extends CakeException {
  const PayjoinSessionError(super.message);
}

/// A session failure that a later attempt may still overcome — transient
/// relay trouble, session expiry, polling timeouts.
class RecoverableError extends PayjoinSessionError {
  const RecoverableError(super.message);
}
