import "package:cw_monero/exceptions/monero_transaction_creation_exception.dart";

class MoneroTransactionNoInputsException extends MoneroTransactionCreationException {
  MoneroTransactionNoInputsException(int inputsSize)
      : inputsSize = inputsSize,
        super("Not enough inputs ($inputsSize) selected. Please select more under Coin Control");

  int inputsSize;
}
