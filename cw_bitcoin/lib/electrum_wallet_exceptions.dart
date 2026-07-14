import "package:cw_core/exceptions/cake_exception.dart";
import 'package:bitcoin_base/bitcoin_base.dart';

// class RichardIsAFuckingIdiotException {...}

class RbfException extends CakeException {
  const RbfException(super.message);
}

class WalletKeysException extends CakeException {
  const WalletKeysException(super.message);
}

class ElectrumResponseException extends ServerResponseException {
  const ElectrumResponseException(super.message);
}

class PayjoinException extends CakeException {
  const PayjoinException(super.message);
}

class PayjoinSenderInitException extends PayjoinException {
  const PayjoinSenderInitException(super.message);
}

class PayjoinReceiverInitException extends PayjoinException {
  const PayjoinReceiverInitException(super.message);
}


class PayjoinSenderException extends PayjoinException {
  const PayjoinSenderException(super.message);
}


class BadAddressTypeException extends CakeException {
  const BadAddressTypeException(super.message, this.addressType);

  final BitcoinAddressType addressType;
}


class PayjoinReceiverException extends PayjoinException {
  const PayjoinReceiverException(super.message);
}