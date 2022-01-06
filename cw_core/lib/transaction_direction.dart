enum TransactionDirection { incoming, outgoing }

TransactionDirection parseTransactionDirectionFromInt(int raw) {
  switch (raw) {
    case 0: return TransactionDirection.incoming;
    case 1: return TransactionDirection.outgoing;
    default: return null;
  }
}

TransactionDirection parseTransactionDirectionFromNumber(String raw) {
  switch (raw) {
    case "0": return TransactionDirection.incoming;
    case "1": return TransactionDirection.outgoing;
    default: return null;
  }
}