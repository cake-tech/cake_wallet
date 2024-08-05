class WowneroTransactionCreationException implements Exception {
  WowneroTransactionCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}