class EthereumTransactionCreationException implements Exception {
  final String exceptionMessage;

  EthereumTransactionCreationException(
      {this.exceptionMessage = 'Wrong balance. Not enough Ether on your balance.'});

  @override
  String toString() => exceptionMessage;
}
