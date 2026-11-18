import 'package:cw_core/wallet_info.dart';

class WalletGroup {
  WalletGroup(this.groupKey) : wallets = [];

  /// Primary identifier for the group: the wallets' `groupId` (the `walletGroup` row id).
  final String groupKey;

  /// Child wallets that share the same group key
  final List<WalletInfo> wallets;

  /// Group name from the `walletGroup` row, editable for every group (single ones too)
  String? groupName;

  /// Sets the group name in memory.
  void setCustomName(String name) {
    groupName = name;
  }
}
