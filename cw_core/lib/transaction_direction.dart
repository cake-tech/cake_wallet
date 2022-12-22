enum TransactionDirection { incoming, outgoing }

TransactionDirection parseTransactionDirectionFromInt(int raw) {
  switch (raw) {
    case 0:
      return TransactionDirection.incoming;
    case 1:
      return TransactionDirection.outgoing;
    default:
      throw Exception('Unexpected token: raw for TransactionDirection parseTransactionDirectionFromInt');
  }
}

TransactionDirection parseTransactionDirectionFromNumber(String raw) {
  switch (raw) {
    case "0":
      return TransactionDirection.incoming;
    case "1":
      return TransactionDirection.outgoing;
    default:
      throw Exception('Unexpected token: raw for TransactionDirection parseTransactionDirectionFromNumber');
  }
}
int parseTransactionDirectionFromType(TransactionDirection raw) {
  switch (raw) {
    case TransactionDirection.incoming:
      return 0;
    case TransactionDirection.outgoing:
      return 1;
    default:
      throw Exception('Unexpected token: raw for TransactionDirection parseTransactionDirectionFromType');
  }
}
