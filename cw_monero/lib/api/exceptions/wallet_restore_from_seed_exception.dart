class WalletRestoreFromSeedException implements Exception {
  WalletRestoreFromSeedException({required this.message});
  
  final String message;
}