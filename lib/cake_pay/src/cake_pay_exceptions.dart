import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/exceptions/cake_exception.dart";

class CakePayUnauthorizedException extends CakeException {
  const CakePayUnauthorizedException()
      : super("Cake Pay session is no longer valid, please log in again.");

  @override
  String toString() => S.current.cakepay_session_expired;
}

class CakePayResponseException extends ServerResponseException {
  const CakePayResponseException(super.message);
}

class CakePayNoDataException extends CakeException {
  const CakePayNoDataException(super.message);
}

class CakePayApiException extends CakeException {
  const CakePayApiException(super.message);
}

class CakePayRedemptionLinkInvalidException extends CakeException {
  const CakePayRedemptionLinkInvalidException() : super("Gift card link is invalid.");

  @override
  String toString() => S.current.cakepay_gift_link_invalid;
}
