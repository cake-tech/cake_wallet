abstract class CakeException implements Exception {
  const CakeException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ConnectionException extends CakeException {
  const ConnectionException(super.message);
}