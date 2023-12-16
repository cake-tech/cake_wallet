class ApiException implements Exception {
  final String code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => '${this.runtimeType}(code: $code, message: $message)';
}