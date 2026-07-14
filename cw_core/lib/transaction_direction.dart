import "package:cw_core/exceptions/cake_exception.dart";

enum TransactionDirection { incoming, outgoing }

TransactionDirection parseTransactionDirectionFromInt(int raw) {
  switch (raw) {
    case 0:
      return TransactionDirection.incoming;
    case 1:
      return TransactionDirection.outgoing;
    default:
      throw DeserializeException('Unexpected token: raw for TransactionDirection parseTransactionDirectionFromInt');
  }
}

TransactionDirection parseTransactionDirectionFromNumber(String raw) {
  switch (raw) {
    case "0":
      return TransactionDirection.incoming;
    case "1":
      return TransactionDirection.outgoing;
    default:
      throw DeserializeException('Unexpected token: raw for TransactionDirection parseTransactionDirectionFromNumber');
  }
}