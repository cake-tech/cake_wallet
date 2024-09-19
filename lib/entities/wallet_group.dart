import 'package:cw_core/wallet_info.dart';

class WalletGroup {
  WalletGroup(this.parentAddress) : wallets = [];

  /// Main identifier for each group, compulsory.
  final String parentAddress;

  /// Child wallets that share the same parent address within this group
  List<WalletInfo> wallets;

  /// Custom name for the group, editable for multi-child wallet groups
  String? groupName;

  /// Allows editing of the group name (only for multi-child groups).
  void setCustomName(String name) {
    if (wallets.length > 1) {
      groupName = name;
    }
  }
}
