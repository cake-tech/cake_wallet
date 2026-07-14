abstract class CakeException implements Exception {
  const CakeException(this.message);
  final String message;
}

class ConnectionException extends CakeException {
  const ConnectionException(super.message);
}