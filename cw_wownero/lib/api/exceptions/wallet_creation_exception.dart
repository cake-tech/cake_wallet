class WalletCreationException implements Exception {
  WalletCreationException({required this.message});

  final String message;

  @override
  String toString() => message;
}
