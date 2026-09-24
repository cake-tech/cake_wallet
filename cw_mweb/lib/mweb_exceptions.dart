class MwebConnectionException implements Exception {
  const MwebConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}