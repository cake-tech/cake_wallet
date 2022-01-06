class BitcoinCommitTransactionException implements Exception {
  @override
  String toString() => 'Transaction commit is failed.';
}