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
    _loadCustomGroupNames();
  }

  String _resolveGroupKey(WalletInfo walletInfo) {
    if (walletInfo.hashedWalletIdentifier != null &&
        walletInfo.hashedWalletIdentifier!.isNotEmpty) {
      return walletInfo.hashedWalletIdentifier!;
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
    for (var group in walletGroups) {
      final key = 'wallet_group_name_${group.groupKey}';
      final groupName = _sharedPreferences.getString(key);
      if (groupName != null && group.wallets.length > 1) {
        group.groupName = groupName;
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
    _saveCustomGroupName(groupKey, name);
  }

  /// When user opens wallet, check if it has a real hash.
  ///
  /// If not, migrate the ENTIRE old group so they keep the same group name
  /// and end up with the same new hash (preserving grouping).
  Future<void> ensureGroupHasHashedIdentifier(WalletBase openedWallet) async {
    final info = openedWallet.walletInfo;

    if (info.hashedWalletIdentifier?.isNotEmpty ?? false) {
      updateWalletGroups();
      return;
    }

    final oldGroupKey = info.parentAddress?.isNotEmpty == true ? info.parentAddress! : null;
    final walletsToMigrate = oldGroupKey != null
        ? _walletInfoSource.values.where((w) => (w.parentAddress ?? w.address) == oldGroupKey).toList()
        : [info];

    if (oldGroupKey != null && walletsToMigrate.isEmpty) return;

    final newHash = createHashedWalletIdentifier(openedWallet);

    if (oldGroupKey != null) {
      await _migrateGroupName(oldGroupKey, newHash);
    }

    // This throttle is here so we don't overwhelm the app when we have a lot of wallets we want to migrate.
    const maxConcurrent = 3;
    for (var i = 0; i < walletsToMigrate.length; i += maxConcurrent) {
      final batch = walletsToMigrate.skip(i).take(maxConcurrent);
      await Future.wait(batch.map((w) {
        w.hashedWalletIdentifier = newHash;
        return w.save();
      }));
    }

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
