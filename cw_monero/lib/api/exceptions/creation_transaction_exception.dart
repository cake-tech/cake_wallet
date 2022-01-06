class CreationTransactionException implements Exception {
  CreationTransactionException({this.message});
  
  final String message;

  @override
  String toString() => message;
}