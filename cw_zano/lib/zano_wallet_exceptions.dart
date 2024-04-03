class ZanoWalletException implements Exception {
  final String message;

  ZanoWalletException(this.message);
  @override
  String toString() => '${this.runtimeType} (message: $message)';
}

class RestoreFromKeysException extends ZanoWalletException {
  RestoreFromKeysException(String message) : super(message);
}

class TransferException extends ZanoWalletException {
  TransferException(String message): super(message);
}