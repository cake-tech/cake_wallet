import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cw_core/wallet_info.dart";

class WalletGroup {
  WalletGroup(
      this.groupKey, {
        List<WalletInfo> wallets = const [],
        this.groupName,
        this.icon,
      }) : wallets = List.unmodifiable(wallets);


  final String groupKey;
  final List<WalletInfo> wallets;
  final String? groupName;
  final WalletIcon? icon;

  WalletGroup copyWith({
    List<WalletInfo>? wallets,
    String? groupName,
    WalletIcon? icon,
  }) =>
      WalletGroup(
        groupKey,
        wallets: wallets ?? this.wallets,
        groupName: groupName ?? this.groupName,
        icon: icon ?? this.icon,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WalletGroup &&
              other.groupKey == groupKey &&
              other.groupName == groupName &&
              other.icon == icon &&
              _sameWallets(other.wallets, wallets);

  @override
  int get hashCode =>
      Object.hash(groupKey, groupName, icon, Object.hashAll(wallets.map((w) => w.id)));

  static bool _sameWallets(List<WalletInfo> a, List<WalletInfo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}