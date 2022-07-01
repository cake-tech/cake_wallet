class WalletOpeningException implements Exception {
  WalletOpeningException({this.message});

  final String? message;

  @override
  String toString() => message!;
}