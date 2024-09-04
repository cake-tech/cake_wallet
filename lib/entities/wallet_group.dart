import 'package:cw_core/wallet_info.dart';

class WalletGroup {
  WalletGroup(this.parentAddress) : wallets = [];

  /// Main identifier for each group, compulsory.
  final String parentAddress;

  /// Represents the lead wallet of the group (parent or first child)
  WalletInfo? leadWallet;

  /// Child wallets that share the same parent address within this group
  List<WalletInfo> wallets;

  // Update the leadWallet based on whether the parent wallet exists
  void updateLeadWallet() {
    if (wallets.isEmpty) {
      // No wallets left, leadWallet should be null
      leadWallet = null;
    } else {
      // Find the parent wallet, which has a null parentAddress
      leadWallet = wallets.firstWhere(
        (wallet) => wallet.parentAddress == null,
        // Use the first child wallet if no parent exists
        orElse: () => wallets.first,
      );
    }
  }
}
