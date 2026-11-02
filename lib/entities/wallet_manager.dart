import 'package:cake_wallet/entities/hash_wallet_identifier.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletManager {
  WalletManager(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  final List<WalletGroup> walletGroups = [];

  Future<void> updateWalletGroups() async {
    walletGroups.clear();

    for (final walletInfo in await WalletInfo.getAll()) {
      final groupKey = _resolveGroupKey(walletInfo);
      final group = _getOrCreateGroup(groupKey);
      group.wallets.add(walletInfo);
    }

    walletGroups.removeWhere((g) => g.wallets.isEmpty);
    _loadCustomGroupNames();
  }

  String _resolveGroupKey(WalletInfo walletInfo) {
    final hash = walletInfo.hashedWalletIdentifier;
    if (hash != null && hash.isNotEmpty) {
      return hash;
    }

    final address = walletInfo.parentAddress ?? walletInfo.address;
    return address.isNotEmpty ? address : walletInfo.id;
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

  void addWallet(WalletInfo walletInfo) {
    final groupKey = _resolveGroupKey(walletInfo);
    final group = _getOrCreateGroup(groupKey);
    group.wallets.add(walletInfo);
  }

  void removeWallet(WalletInfo walletInfo) {
    final groupKey = _resolveGroupKey(walletInfo);
    final group = _getOrCreateGroup(groupKey);
    group.wallets.remove(walletInfo);

    if (group.wallets.isEmpty) {
      walletGroups.remove(group);
    }
  }

  List<WalletInfo> getWalletsInGroup(String groupKey) {
    return walletGroups
        .firstWhere(
          (g) => g.groupKey == groupKey,
          orElse: () => WalletGroup(groupKey),
        )
        .wallets;
  }

  void _loadCustomGroupNames() {
    for (final group in walletGroups) {
      final groupName = _sharedPreferences.getString(_groupNameKey(group.groupKey));
      if (groupName != null && groupName.isNotEmpty) {
        group.groupName = groupName;
      }
    }
  }

  // TODO(serhii): group key can be hashedWalletIdentifier (plaintext seed in debug builds); drop with DB groups.
  String _groupNameKey(String groupKey) => 'wallet_group_name_$groupKey';

  Future<void> setGroupName(String groupKey, String name) async {
    final trimmedName = name.trim();
    if (groupKey.isEmpty || trimmedName.isEmpty) return;

    await _sharedPreferences.setString(_groupNameKey(groupKey), trimmedName);
    walletGroups.where((g) => g.groupKey == groupKey).firstOrNull?.setCustomName(trimmedName);
  }

  // ---------------------------------------------------------------------------
  // This performs a Group-Based Lazy Migration:
  // If the user opens a wallet in an old group,
  // we migrate ALL wallets that share its old group key to a new hash.
  // ---------------------------------------------------------------------------

  /// When a user opens a wallet, check if it has a real hash.
  /// If not, migrate the ENTIRE old group so they keep the same group name
  /// and end up with the same new hash (preserving grouping).
  Future<void> ensureGroupHasHashedIdentifier(WalletBase openedWallet) async {
    WalletInfo walletInfo = openedWallet.walletInfo;

    // If the openedWallet already has an hash, then there is nothing to do
    if (walletInfo.hashedWalletIdentifier != null &&
        walletInfo.hashedWalletIdentifier!.isNotEmpty) {
      await updateWalletGroups(); // Still skeptical of calling this here. Looking for a better spot.
      return;
    }

    // Identify the old group key for this wallet
    final oldGroupKey = _resolveGroupKey(walletInfo); // parentAddress fallback

    // Find all wallets that share this old group key (i.e the old group)
    final oldGroupWallets = (await WalletInfo.getAll()).where((w) {
      final key = w.hashedWalletIdentifier != null && w.hashedWalletIdentifier!.isNotEmpty
          ? w.hashedWalletIdentifier
          : (w.parentAddress ?? w.address);
      return key == oldGroupKey;
    }).toList();

    if (oldGroupWallets.isEmpty) {
      // This shouldn't happen, but just in case it does, we return.
      return;
    }

    // Next, we determine the new group hash for these wallets
    // Since they share the same seed, we can assign that group hash
    // to all the wallets to preserve grouping.
    final newGroupHash = createHashedWalletIdentifier(openedWallet);

    // Migrate the old group name from oldGroupKey(i.e parentAddress) to newGroupHash
    await _migrateGroupName(oldGroupKey, newGroupHash);

    // Then we assign this new hash to each wallet in that old group and save them
    for (final wallet in oldGroupWallets) {
      wallet.hashedWalletIdentifier = newGroupHash;
      await wallet.save();
    }

    // Finally, we rebuild the groups so that these wallets are now in the new group
    await updateWalletGroups();
  }

  /// Copy an old group name to the new group key, then remove the old key.
  Future<void> _migrateGroupName(String oldGroupKey, String newGroupKey) async {
    final oldNameKey = 'wallet_group_name_$oldGroupKey';
    final newNameKey = 'wallet_group_name_$newGroupKey';

    final oldGroupName = _sharedPreferences.getString(oldNameKey);
    if (oldGroupName != null) {
      await _sharedPreferences.setString(newNameKey, oldGroupName);
      await _sharedPreferences.remove(oldNameKey);
    }
  }

  String? getGroupName(WalletInfo walletInfo) {
    try {
      final groupKey = _resolveGroupKey(walletInfo);
      final group = walletGroups.firstWhere((g) => g.groupKey == groupKey);
      return group.groupName;
    } catch (_) {
      return null;
    }
  }
}
