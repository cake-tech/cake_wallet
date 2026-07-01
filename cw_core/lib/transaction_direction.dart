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