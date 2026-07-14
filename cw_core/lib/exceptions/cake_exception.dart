
import "package:cw_core/currency.dart";

abstract class CakeException implements Exception {
  const CakeException(this.message);

  final String message;
}

class BadWalletTypeException extends CakeException {
  const BadWalletTypeException(super.message);
}

class BadCurrencyException extends CakeException {

  const BadCurrencyException(super.message, this.curr);
  final Currency curr;
}

class BadCurrencyPairException extends CakeException {
  const BadCurrencyPairException(super.message, this.from, this.to);

  final Currency from;
  final Currency to;
}

class ConnectionException extends CakeException {
  const ConnectionException(super.message);
}

class ServerResponseException extends CakeException {
  const ServerResponseException(super.message);
}

class CurrencyParseException extends CakeException {
  const CurrencyParseException(super.message);
}

class DeserializeException extends CakeException {
  const DeserializeException(super.message);
}

class WalletOpenException extends CakeException {
  const WalletOpenException(super.message);
}

class WalletNotFoundException extends WalletOpenException {
  const WalletNotFoundException() : super("Wallet not found");
}

class AccountNotFoundException extends CakeException {
  const AccountNotFoundException(String name)
      : name = name,
        super("Account not found: $name");
  final String name;
}

class WalletCreationException extends CakeException {
  const WalletCreationException(super.message);
}

class BadWalletDataException extends WalletCreationException {
  const BadWalletDataException(super.message);
}

class BadKeysException extends BadWalletDataException {
  const BadKeysException(super.message);
}

class BadMnemonicException extends BadWalletDataException {
  const BadMnemonicException(super.message);
}

class TransactionGenerationException extends CakeException {
  const TransactionGenerationException(super.message);
}

class TransactionSendingException extends CakeException {
  const TransactionSendingException(super.message);
}

class ScanValueException extends CakeException {
  const ScanValueException(super.message);
}

class NodeLookupException extends CakeException {
  const NodeLookupException(super.message);
}

class BadChainIdException extends CakeException {
  const BadChainIdException(super.message);
}

class MessageSignException extends CakeException {
  const MessageSignException(super.message);
}

class HardwareWalletNotConnectedException extends CakeException {
  const HardwareWalletNotConnectedException(super.message);
}

class HardwareWalletResponseException extends CakeException {
  const HardwareWalletResponseException(super.message);
}