class SalviumTransactionCreationException implements Exception {
  SalviumTransactionCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}