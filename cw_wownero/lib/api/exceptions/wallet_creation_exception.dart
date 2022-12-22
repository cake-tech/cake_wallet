class WalletCreationException implements Exception {
  WalletCreationException({this.message});

  final String? message;

  @override
  String toString() => message!;
}