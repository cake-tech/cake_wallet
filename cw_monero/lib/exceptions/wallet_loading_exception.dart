class WalletLoadingException implements Exception {
  WalletLoadingException({this.message});

  final String message;

  @override
  String toString() => message;
}