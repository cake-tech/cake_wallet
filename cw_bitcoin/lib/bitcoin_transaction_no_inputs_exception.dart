class BitcoinTransactionNoInputsException implements Exception {
  @override
  String toString() => 'Not enough inputs available';
}
