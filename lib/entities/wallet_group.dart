import 'package:cw_core/wallet_info.dart';

class WalletGroup {
  WalletGroup(this.groupKey) : wallets = [];

  /// Primary identifier for the group. Previously was `parentAddress`.
  /// Now we store either the wallet's hash OR fallback to parentAddress/address.
  final String groupKey;

  /// Child wallets that share the same group key
  final List<WalletInfo> wallets;

  /// Custom name for the group, editable for multi-child wallet groups
  String? groupName;

  /// Allows editing of the group name (only for multi-child groups).
  void setCustomName(String name) {
    if (wallets.length > 1) {
      groupName = name;
    }
  }
}
