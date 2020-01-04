class CreationTransactionException implements Exception {
  final String message;

  CreationTransactionException({this.message});

  @override
  String toString() => message;
}