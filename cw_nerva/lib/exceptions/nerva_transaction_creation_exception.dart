class NervaTransactionCreationException implements Exception {
  NervaTransactionCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}