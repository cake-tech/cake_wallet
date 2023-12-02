class GetWalletStatusResult {
  final int currentDaemonHeight;
  final int currentWalletHeight;
  final bool isDaemonConnected;
  final bool isInLongRefresh;
  final int progress;
  final int walletState;

  GetWalletStatusResult(
      {required this.currentDaemonHeight,
      required this.currentWalletHeight,
      required this.isDaemonConnected,
      required this.isInLongRefresh,
      required this.progress,
      required this.walletState});

  factory GetWalletStatusResult.fromJson(Map<String, dynamic> json) =>
      GetWalletStatusResult(
        currentDaemonHeight: json['current_daemon_height'] as int,
        currentWalletHeight: json['current_wallet_height'] as int,
        isDaemonConnected: json['is_daemon_connected'] as bool,
        isInLongRefresh: json['is_in_long_refresh'] as bool,
        progress: json['progress'] as int,
        walletState: json['wallet_state'] as int,
      );
  /*
     "current_daemon_height": 238049,
   "current_wallet_height": 238038,
   "is_daemon_connected": true,
   "is_in_long_refresh": true,
   "progress": 0,
   "wallet_state": 1

  */
}
