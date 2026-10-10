class EverstakeException implements Exception {
  EverstakeException([this.message = ""]);

  final String message;

  @override
  String toString() => message.isNotEmpty ? message : "EverstakeException";
}
