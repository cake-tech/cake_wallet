import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletManager {
  WalletManager(
    this._walletInfoSource,
    this._sharedPreferences,
  );

  final Box<WalletInfo> _walletInfoSource;
  final SharedPreferences _sharedPreferences;

  final List<WalletGroup> walletGroups = [];

  /// Categorize wallets into groups based on their parentAddress.
  ///
  /// Update the lead wallet for each group and clean up empty groups
  /// i.e remove group if there's no lead wallet (i.e, no wallets left)
  void updateWalletGroups() {
    walletGroups.clear();

    for (var walletInfo in _walletInfoSource.values) {
      final group = _getOrCreateGroup(_resolveParentAddress(walletInfo));
      group.wallets.add(walletInfo);
    }

    walletGroups.removeWhere((group) => group.wallets.isEmpty);

    _loadCustomGroupNames();
  }

  /// Function to determine the correct parentAddress for a wallet.
  ///
  /// If it's a parent wallet (parentAddress is null),
  /// use its own address as parentAddress.
  String _resolveParentAddress(WalletInfo walletInfo) {
    return walletInfo.parentAddress ?? walletInfo.address;
  }

  /// Check if a group with the parentAddress already exists,
  /// If no group exists, create a new one.
  ///
  WalletGroup _getOrCreateGroup(String parentAddress) {
    return walletGroups.firstWhere(
      (group) => group.parentAddress == parentAddress,
      orElse: () {
        final newGroup = WalletGroup(parentAddress);
        walletGroups.add(newGroup);
        return newGroup;
      },
    );
  }

  /// Add a new wallet and update lead wallet after adding.
  void addWallet(WalletInfo walletInfo) {
    final group = _getOrCreateGroup(_resolveParentAddress(walletInfo));
    group.wallets.add(walletInfo);
  }

  /// Removes a wallet from a group i.e when it's deleted.
  ///
  /// Update lead wallet after removing,
  /// Remove the group if it's empty (i.e., no lead wallet).
  void removeWallet(WalletInfo walletInfo) {
    final group = _getOrCreateGroup(_resolveParentAddress(walletInfo));
    group.wallets.remove(walletInfo);

    if (group.wallets.isEmpty) {
      walletGroups.remove(group);
    }
  }

  /// Returns all the child wallets within a group.
  ///
  /// If the group is not found, returns an empty group with no wallets.
  List<WalletInfo> getWalletsInGroup(String parentAddress) {
    return walletGroups
        .firstWhere(
          (group) => group.parentAddress == parentAddress,
          orElse: () => WalletGroup(parentAddress),
        )
        .wallets;
  }

  /// Iterate through all groups and load their custom names from storage
  void _loadCustomGroupNames() {
    for (var group in walletGroups) {
      final groupName = _sharedPreferences.getString('wallet_group_name_${group.parentAddress}');
      if (groupName != null && group.wallets.length > 1) {
        group.groupName = groupName; // Restore custom name
      }
    }
  }

  /// Save custom name for a group
  void _saveCustomGroupName(String parentAddress, String name) {
    _sharedPreferences.setString('wallet_group_name_$parentAddress', name);
  }

  // Set custom group name and persist it
  void setGroupName(String parentAddress, String name) {
    if (parentAddress.isEmpty || name.isEmpty) return;

    final group = walletGroups.firstWhere((group) => group.parentAddress == parentAddress);
    group.setCustomName(name);
    _saveCustomGroupName(parentAddress, name); // Persist the custom name
  }
}
