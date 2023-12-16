class CreateWalletException implements Exception {
  final String message;

  CreateWalletException(this.message): super();
  @override
  String toString() => '${this.runtimeType}(message: $message)';
}