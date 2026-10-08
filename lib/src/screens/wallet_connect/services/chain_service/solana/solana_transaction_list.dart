List<String> readSolanaSignAllTransactions(Object? transactions) {
  if (transactions is! List) {
    throw const FormatException("transactions");
  }

  return List<String>.from(transactions);
}
