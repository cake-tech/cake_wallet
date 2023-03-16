class EthereumTransactionCreationException implements Exception {
  EthereumTransactionCreationException();

  @override
  String toString() => 'Wrong balance. Not enough Ether on your balance.';
}