class WalletRestoreFromSeedException implements Exception {
  WalletRestoreFromSeedException({this.message});
  
  final String message;
}