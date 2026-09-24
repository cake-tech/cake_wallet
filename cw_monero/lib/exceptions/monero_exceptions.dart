
import "package:cw_core/exceptions/cake_exception.dart";

class MoneroNodeResponseException extends ServerResponseException {
  const MoneroNodeResponseException(super.message);
}

class KeyImageException extends CakeException {
  const KeyImageException(super.message);
}

class MoneroWalletException extends CakeException {
  const MoneroWalletException(super.message);
}