class WalletOpeningException implements Exception {
  WalletOpeningException({required this.message});

  final String message;

  @override
  String toString() => message;
}