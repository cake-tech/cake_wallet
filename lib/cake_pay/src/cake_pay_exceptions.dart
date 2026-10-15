import "package:cw_core/exceptions/cake_exception.dart";
import 'package:cake_wallet/generated/i18n.dart';

class CakePayUnauthorizedException implements Exception {
  const CakePayUnauthorizedException();

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

class CakePayApiException implements Exception {
  const CakePayApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CakePayRedemptionLinkInvalidException implements Exception {
  const CakePayRedemptionLinkInvalidException();

  @override
  String toString() => S.current.cakepay_gift_link_invalid;
}
