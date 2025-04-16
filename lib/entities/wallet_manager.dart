import 'dart:math';

import 'package:cake_wallet/entities/hash_wallet_identifier.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletManager {
  WalletManager(this._walletInfoSource, this._sharedPreferences);

  final Box<WalletInfo> _walletInfoSource;
  final SharedPreferences _sharedPreferences;

  final List<WalletGroup> walletGroups = [];

  void updateWalletGroups() {
    walletGroups.clear();

    for (final walletInfo in _walletInfoSource.values) {
      final groupKey = _resolveGroupKey(walletInfo);
      final group = _getOrCreateGroup(groupKey);
      group.wallets.add(walletInfo);
    }

    walletGroups.removeWhere((g) => g.wallets.isEmpty);
    _applyStoredGroupNames();
  }

  String _resolveGroupKey(WalletInfo walletInfo) {
    if (walletInfo.hashedWalletIdentifier != null &&
        walletInfo.hashedWalletIdentifier!.isNotEmpty) {
      return walletInfo.hashedWalletIdentifier!;
    }

    // Fallback to old logic
    final address = walletInfo.parentAddress ?? walletInfo.address;
    if (address.isEmpty) {
      return Random().nextInt(100000).toString();
    }
    return address;
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

  void _applyStoredGroupNames() {
    for (final group in walletGroups) {
      // We attempt to derive a group name from any of the wallets that already has one.
      final migratedName = group.wallets
          .map((wallet) => wallet.walletGroupName?.trim() ?? '')
          .firstWhere((name) => name.isNotEmpty, orElse: () => '');

      // If none of the wallets have a name, we fall back to the SharedPreferences value.
      String finalGroupName = migratedName;
      if (finalGroupName.isEmpty) {
        final prefsKey = 'wallet_group_name_${group.groupKey}';
        final fallbackName = _sharedPreferences.getString(prefsKey)?.trim() ?? '';

        if (fallbackName.isNotEmpty && group.wallets.length > 1) {
          finalGroupName = fallbackName;
        }
      }

      group.groupName = finalGroupName.isNotEmpty ? finalGroupName : null;

      // We then migrate the group name into each wallet in this group that doesn't have it yet.
      if (finalGroupName.isNotEmpty) {
        for (final wallet in group.wallets) {
          // We would only update it though if the wallet does not have it already
          if ((wallet.walletGroupName?.trim() ?? '').isEmpty) {
            wallet.walletGroupName = finalGroupName;
            wallet.save();
          }
        }
      }
    }
  }

  void _saveCustomGroupName(String groupKey, String name) {
    _sharedPreferences.setString('wallet_group_name_$groupKey', name);
  }

  void setGroupName(String groupKey, String name) {
    if (groupKey.isEmpty || name.isEmpty) return;

    final group = walletGroups.firstWhere((g) => g.groupKey == groupKey);
    group.setCustomName(name);

    for (var walletInfo in group.wallets) {
      walletInfo.walletGroupName = name;
      walletInfo.save();
    }
    _saveCustomGroupName(groupKey, name);
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
      updateWalletGroups(); // Still skeptical of calling this here. Looking for a better spot.
      return;
    }

    // Identify the old group key for this wallet
    final oldGroupKey = _resolveGroupKey(walletInfo); // parentAddress fallback

    // Find all wallets that share this old group key (i.e the old group)
    final oldGroupWallets = _walletInfoSource.values.where((w) {
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
    updateWalletGroups();
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
}
