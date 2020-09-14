class BitcoinTransactionNoInputsException implements Exception {
  @override
  String toString() => 'No inputs for the transaction.';
}