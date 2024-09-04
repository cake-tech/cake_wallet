import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:hive/hive.dart';

class WalletManager {
  WalletManager(this._walletInfoSource);

  final Box<WalletInfo> _walletInfoSource;
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

    walletGroups.removeWhere((group) {
      group.updateLeadWallet();

      return group.leadWallet == null;
    });
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
    group.updateLeadWallet();
  }

  /// Removes a wallet from a group i.e when it's deleted.
  ///
  /// Update lead wallet after removing,
  /// Remove the group if it's empty (i.e., no lead wallet).
  void removeWallet(WalletInfo walletInfo) {
    final group = _getOrCreateGroup(_resolveParentAddress(walletInfo));
    group.wallets.remove(walletInfo);
    group.updateLeadWallet();

    if (group.leadWallet == null) {
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

  /// Return the lead wallet within a group.
  ///
  /// Returns a null leadWallet if the group does not exist.
  WalletInfo? getLeadWalletInGroup(String parentAddress) {
    return walletGroups
        .firstWhere(
          (group) => group.parentAddress == parentAddress,
          orElse: () => WalletGroup(parentAddress),
        )
        .leadWallet;
  }
}
