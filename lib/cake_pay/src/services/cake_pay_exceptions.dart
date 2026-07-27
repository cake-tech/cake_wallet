import "package:cw_core/exceptions/cake_exception.dart";

class CakePayResponseException extends ServerResponseException {
  const CakePayResponseException(super.message);
}

class CakePayNoDataException extends CakeException {
  const CakePayNoDataException(super.message);
}