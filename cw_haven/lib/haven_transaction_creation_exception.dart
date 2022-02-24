class HavenTransactionCreationException implements Exception {
  HavenTransactionCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}