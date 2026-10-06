import 'package:cake_wallet/generated/i18n.dart';

class CakePayUnauthorizedException implements Exception {
  const CakePayUnauthorizedException();

  @override
  String toString() => 'Cake Pay session is no longer valid, please log in again.';
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
