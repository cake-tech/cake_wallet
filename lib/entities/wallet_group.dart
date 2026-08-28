import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cw_core/wallet_info.dart";

class WalletGroup {
  WalletGroup(this.groupKey) : wallets = [];

  /// Primary identifier for the group. Previously was `parentAddress`.
  /// Now we store either the wallet's hash OR fallback to parentAddress/address.
  final String groupKey;

  /// Child wallets that share the same group key
  final List<WalletInfo> wallets;

  /// Custom name for the group, editable for multi-child wallet groups
  String? groupName;

  /// Custom icon for the group (e.g. from the omnichain icon picker). Null
  /// means no custom icon has been set — callers should fall back to
  /// whatever default icon they'd otherwise show.
  WalletIcon? icon;

  /// Allows editing of the group name (only for multi-child groups).
  void setCustomName(String name) {
    if (wallets.length > 1) {
      groupName = name;
    }
  }

  /// Allows editing of the custom icon (only for multi-child groups, same
  /// restriction as [setCustomName] — single wallets show their own coin
  /// icon instead).
  void setCustomIcon(WalletIcon newIcon) {
    if (wallets.length > 1) {
      icon = newIcon;
    }
  }
}