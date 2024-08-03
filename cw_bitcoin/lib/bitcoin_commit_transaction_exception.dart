class BitcoinCommitTransactionException implements Exception {
  String errorMessage;
  BitcoinCommitTransactionException(this.errorMessage);

  @override
  String toString() => errorMessage;
}

