import "package:cw_core/exceptions/cake_exception.dart";

class CakePayUnauthorizedException extends CakeException {
  const CakePayUnauthorizedException()
      : super("Cake Pay session is no longer valid, please log in again.");
}

class CakePayResponseException extends ServerResponseException {
  const CakePayResponseException(super.message);
}

class CakePayNoDataException extends CakeException {
  const CakePayNoDataException(super.message);
}
