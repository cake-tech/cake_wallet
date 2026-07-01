class MoneroTransactionCreationException implements Exception {
  MoneroTransactionCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}