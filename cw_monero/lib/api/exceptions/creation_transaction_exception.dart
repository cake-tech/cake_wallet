class CreationTransactionException implements Exception {
  CreationTransactionException({required this.message});
  
  final String message;

  @override
  String toString() => message;
}