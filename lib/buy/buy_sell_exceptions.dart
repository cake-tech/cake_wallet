import "package:cw_core/exceptions/cake_exception.dart";

class BuySellProviderResponseException extends ServerResponseException {
  const BuySellProviderResponseException(super.message);
}

class BuySellLaunchException extends CakeException {
  const BuySellLaunchException(super.message);
}
