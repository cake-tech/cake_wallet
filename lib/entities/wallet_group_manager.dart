import "dart:async";

import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cw_core/wallet_group_db_entry.dart";
import "package:cw_core/wallet_info.dart";
import "package:mobx/mobx.dart";

/// Manages the persisted grouping of wallets under a shared [WalletInfo.groupId].
///
/// A group's identity is a real, immutable uuid assigned once at creation
/// (see the omnichain wallet-creation flow) and never recomputed afterwards
/// — so renaming a group is a plain `UPDATE name WHERE id = ?`, and never
/// touches any wallet's files or id.
///
/// This class only operates on wallets that already carry a real groupId.
/// Migrating pre-existing wallets that predate this scheme (grouped only via
/// the legacy hash-based identifier) is handled by a separate migration step,
/// not by this class.
class WalletGroupManager {
  final List<WalletGroup> walletGroups = [];
  final Observable<int> groupsRevision = Observable(0);

  void _markGroupsChanged() => runInAction(() => groupsRevision.value++);

  /// Serializes concurrent calls to [updateWalletGroups] so they never
  /// interleave.
  Future<void> _lastUpdate = Future.value();

  Future<List<WalletGroup>> getAllGroups() => WalletGroupDbEntry.getAll().then(
        (groups) => groups
            .map((g) => WalletGroup(g.id)
              ..groupName = g.name
              ..icon = _iconFromPersisted(g))
            .toList(),
      );

  Future<List<String>> getAllGroupNames() => WalletGroupDbEntry.getAll().then(
        (groups) =>
            groups.map((g) => g.name).whereType<String>().where((name) => name.isNotEmpty).toList(),
      );

  Future<bool> groupNameExists(String name) =>
      getAllGroupNames().then((names) => names.contains(name));

  /// Creates the persisted group row. Must be called before any wallet is
  /// tagged with this [groupId] via [setGroupIdForWalletInfo], and before
  /// [setGroupName]/[setGroupIcon] are used on it.
  Future<void> createWalletGroup(String groupId) => WalletGroupDbEntry.external(id: groupId).save();

  Future<void> setGroupIdForWalletInfo(WalletInfo walletInfo, String groupId) async {
    walletInfo.groupId = groupId;
    await walletInfo.save();
  }

  Future<void> updateWalletGroups() async {
    final waitFor = _lastUpdate;
    final done = Completer<void>();
    _lastUpdate = done.future;

    await waitFor;

    try {
      final rebuiltGroups = <WalletGroup>[];
      final allWallets = await WalletInfo.getAll();
      final persistedGroups = {for (final g in await WalletGroupDbEntry.getAll()) g.id: g};

      final byGroupId = <String, List<WalletInfo>>{};
      final ungrouped = <WalletInfo>[];
      for (final walletInfo in allWallets) {
        final groupId = walletInfo.groupId;
        if (groupId != null && groupId.isNotEmpty && persistedGroups.containsKey(groupId)) {
          byGroupId.putIfAbsent(groupId, () => []).add(walletInfo);
        } else {
          ungrouped.add(walletInfo);
        }
      }

      for (final entry in byGroupId.entries) {
        final persisted = persistedGroups[entry.key]!;
        final group = WalletGroup(entry.key)
          ..wallets.addAll(entry.value)
          ..groupName = persisted.name
          ..icon = _iconFromPersisted(persisted);
        rebuiltGroups.add(group);
      }

      for (final walletInfo in ungrouped) {
        rebuiltGroups.add(WalletGroup(resolveGroupKey(walletInfo))..wallets.add(walletInfo));
      }

      walletGroups
        ..clear()
        ..addAll(rebuiltGroups);

      _markGroupsChanged();
    } finally {
      done.complete();
    }
  }

  WalletIcon? _iconFromPersisted(WalletGroupDbEntry persisted) {
    final typeName = persisted.iconType;
    final value = persisted.iconValue;
    if (typeName == null || value == null) return null;

    final type = WalletIconType.values.asNameMap()[typeName];
    if (type == null) return null; // unknown/future type this build doesn't know about

    final colorIndex = int.tryParse(persisted.iconColor ?? '') ?? 0;
    final backgroundEnabled = persisted.iconBg != 'false';

    return WalletIcon(
      type: type,
      value: value,
      colorIndex: colorIndex,
      backgroundEnabled: backgroundEnabled,
    );
  }

  /// Resolves the key this wallet is (or will be) filed under in
  /// [walletGroups]: its real [WalletInfo.groupId] if it has one, otherwise
  /// its own id (a wallet with no group is its own group of one).
  String resolveGroupKey(WalletInfo walletInfo) {
    final groupId = walletInfo.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      return groupId;
    }
    return walletInfo.id;
  }

  /// Adds a wallet to the in-memory view of its (already-persisted) group.
  /// This never creates a new persisted group: group membership
  /// ([WalletInfo.groupId]) must already be set on the wallet itself.
  void addWallet(WalletInfo walletInfo) {
    final groupKey = resolveGroupKey(walletInfo);
    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupKey);
    if (group != null) {
      if (!group.wallets.contains(walletInfo)) group.wallets.add(walletInfo);
    } else {
      walletGroups.add(WalletGroup(groupKey)..wallets.add(walletInfo));
    }
    _markGroupsChanged();
  }

  void removeWallet(WalletInfo walletInfo) {
    final groupKey = resolveGroupKey(walletInfo);
    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupKey);
    if (group == null) return;

    group.wallets.remove(walletInfo);
    if (group.wallets.isEmpty) {
      walletGroups.remove(group);
    }

    _markGroupsChanged();
  }

  List<WalletInfo> getWalletsInGroup(String groupKey) => walletGroups
      .firstWhere(
        (g) => g.groupKey == groupKey,
        orElse: () => WalletGroup(groupKey),
      )
      .wallets;

  /// Renames a group. This is a single `UPDATE name = ? WHERE id = ?`: no
  /// wallet file is touched, and no wallet's id/name is changed.
  Future<void> setGroupName(String groupKey, String name) async {
    if (groupKey.isEmpty || name.isEmpty) return;

    final persisted = await WalletGroupDbEntry.get(groupKey);
    if (persisted == null) {
      throw Exception(
          'setGroupName: no group row for id "$groupKey" — was createWalletGroup called first?');
    }

    persisted.name = name;
    await persisted.save();

    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupKey);
    group?.groupName = name;
    _markGroupsChanged();
  }

  Future<void> setGroupIcon(String groupKey, WalletIcon icon) async {
    if (groupKey.isEmpty) return;

    final persisted = await WalletGroupDbEntry.get(groupKey);
    if (persisted == null) return;

    persisted.iconType = icon.type.name;
    persisted.iconValue = icon.value;
    persisted.iconColor = icon.colorIndex.toString();
    persisted.iconBg = icon.backgroundEnabled.toString();
    await persisted.save();

    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupKey);
    group?.icon = icon;
    _markGroupsChanged();
  }

  Future<void> setGroupIconForWallet(WalletInfo walletInfo, WalletIcon icon) async {
    final groupKey = walletInfo.groupId;
    if (groupKey == null || groupKey.isEmpty) return;
    await setGroupIcon(groupKey, icon);
  }

  String? getGroupName(WalletInfo walletInfo) {
    final groupId = walletInfo.groupId;
    if (groupId == null || groupId.isEmpty) return null;

    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupId);
    if (group == null) return null;
    return group.groupName;
  }

  WalletIcon? getGroupIcon(WalletInfo walletInfo) {
    final groupId = walletInfo.groupId;
    if (groupId == null || groupId.isEmpty) return null;

    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupId);
    if (group == null) return null;
    return group.icon;
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
