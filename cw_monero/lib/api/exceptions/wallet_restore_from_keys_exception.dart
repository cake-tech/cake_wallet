class WalletRestoreFromKeysException implements Exception {
  WalletRestoreFromKeysException({required this.message});
  
  final String message;

  @override
  String toString() => message;
}