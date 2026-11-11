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

/// A session failure no retry can overcome: the session expired, the payjoin
/// library closed it, or the proposal was rejected. The session should be
/// marked unrecoverable so the fallback transaction can be broadcast.
class UnrecoverableError extends PayjoinSessionError {
  const UnrecoverableError(super.message);
}

/// Thrown when a send targets a `pj=` endpoint an earlier send already used.
/// The endpoint is a single-use mailbox, so a second payjoin to it would
/// replay or collide with the earlier session.
class PayjoinEndpointAlreadyUsedError extends PayjoinSessionError {
  const PayjoinEndpointAlreadyUsedError()
      : super("This payment request was already used for a payjoin. "
            "Scan a new one or send without payjoin.");
}
