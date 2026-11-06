import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_group_db_entry.dart';
import 'package:cw_core/wallet_info.dart';

class WalletManager {
  final List<WalletGroup> walletGroups = [];

  Future<void> updateWalletGroups() async {
    walletGroups.clear();

    for (final walletInfo in await WalletInfo.getAll()) {
      final groupKey = _resolveGroupKey(walletInfo);
      final group = _getOrCreateGroup(groupKey);
      group.wallets.add(walletInfo);
    }

    walletGroups.removeWhere((g) => g.wallets.isEmpty);
    await _loadGroupNames();
  }

  /// Every wallet has a `groupId` after the migration; `id` is only a safety net.
  String _resolveGroupKey(WalletInfo walletInfo) {
    final groupId = walletInfo.groupId;
    return (groupId != null && groupId.isNotEmpty) ? groupId : walletInfo.id;
  }

  WalletGroup _getOrCreateGroup(String groupKey) {
    return walletGroups.firstWhere(
      (g) => g.groupKey == groupKey,
      orElse: () {
        final newGroup = WalletGroup(groupKey);
        walletGroups.add(newGroup);
        return newGroup;
      },
    );
  }

  Future<void> _loadGroupNames() async {
    final names = {for (final g in await WalletGroupDbEntry.getAll()) g.id: g.name};
    for (final group in walletGroups) {
      final groupName = names[group.groupKey];
      if (groupName != null && groupName.isNotEmpty) {
        group.groupName = groupName;
      }
    }
  }

  Future<void> setGroupName(String groupKey, String name) async {
    final trimmedName = name.trim();
    if (groupKey.isEmpty || trimmedName.isEmpty) return;

    await WalletGroupDbEntry.updateName(groupKey, trimmedName);
    walletGroups.where((g) => g.groupKey == groupKey).firstOrNull?.setCustomName(trimmedName);
  }

  String? getGroupName(WalletInfo walletInfo) {
    final groupKey = _resolveGroupKey(walletInfo);
    return walletGroups.where((g) => g.groupKey == groupKey).firstOrNull?.groupName;
  }
}
