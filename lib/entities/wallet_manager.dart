import "dart:async";

import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cw_core/wallet_group.dart" as db;
import "package:cw_core/wallet_info.dart";
import "package:mobx/mobx.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Manages the (persisted) grouping of wallets that share the same seed.
///
/// A group's identity ([WalletInfo.groupId]) is assigned once, either at
/// creation time or via a one-time, opportunistic backfill from the legacy
/// SharedPreferences-based scheme (below). It is never recomputed afterwards,
/// so renaming a group is a plain `UPDATE name WHERE id = ?` and never
/// touches wallet files or wallet ids.
class WalletManager {
  WalletManager(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  final List<WalletGroup> walletGroups = [];
  final Observable<int> groupsRevision = Observable(0);

  void _markGroupsChanged() => runInAction(() => groupsRevision.value++);

  /// This is used to ensure that concurrent calls to `updateWalletGroups` do not
  Future<void> _lastUpdate = Future.value();

  Future<void> updateWalletGroups() async {
    final waitFor = _lastUpdate;
    final done = Completer<void>();
    _lastUpdate = done.future;

    await waitFor;

    try {
      await _backfillLegacyGroups();

      final rebuiltGroups = <WalletGroup>[];
      final allWallets = await WalletInfo.getAll();
      final persistedGroups = {for (final g in await db.WalletGroup.getAll()) g.id: g};

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

  WalletIcon? _iconFromPersisted(db.WalletGroup persisted) {
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

  /// One-time, opportunistic migration: for wallets that don't have a
  /// [WalletInfo.groupId] yet, cluster them using the legacy identifier
  /// (hashedWalletIdentifier, falling back to parentAddress/address), create
  /// a real [db.WalletGroup] row per distinct cluster of 2+ wallets (carrying
  /// over whatever custom name/icon was stored in SharedPreferences for that
  /// cluster), and assign that group's id to each member. This never runs
  /// again for wallets that already have a groupId.
  Future<void> _backfillLegacyGroups() async {
    final ungrouped =
        (await WalletInfo.getAll()).where((w) => w.groupId == null || w.groupId!.isEmpty).toList();
    if (ungrouped.isEmpty) return;

    final byLegacyKey = <String, List<WalletInfo>>{};
    for (final w in ungrouped) {
      final key = _legacyGroupKey(w);
      if (key.isEmpty) continue;
      byLegacyKey.putIfAbsent(key, () => []).add(w);
    }

    for (final entry in byLegacyKey.entries) {
      if (entry.value.length < 2) continue;

      final legacyName = _sharedPreferences.getString('wallet_group_name_${entry.key}');
      final legacyIconType = _sharedPreferences.getString('wallet_group_icon_type_${entry.key}');
      final legacyIconValue = _sharedPreferences.getString('wallet_group_icon_value_${entry.key}');
      final legacyIconColor = _sharedPreferences.getInt('wallet_group_icon_color_${entry.key}');
      final legacyIconBg =
          _sharedPreferences.getBool('wallet_group_icon_bg_enabled_${entry.key}');

      final newGroup = db.WalletGroup.external(
        // Reuse the legacy key itself as the persisted group's immutable id
        // (rather than a freshly generated uuid). This keeps resolveGroupKey()
        // stable across the backfill: any caller that computed this same key
        // *before* the group row existed (e.g. while tagging placeholder
        // wallets during omnichain group creation) can keep using it
        // immediately afterwards to look up / rename the now-real group.
        id: entry.key,
        name: legacyName,
        iconType: legacyIconType,
        iconValue: legacyIconValue,
        iconColor: legacyIconColor?.toString(),
        iconBg: legacyIconBg?.toString(),
      );
      await newGroup.save();

      for (final w in entry.value) {
        w.groupId = newGroup.id;
        await w.save();
      }

      // Clean up the legacy SharedPreferences entries now that they live in the DB.
      await _sharedPreferences.remove('wallet_group_name_${entry.key}');
      await _sharedPreferences.remove('wallet_group_icon_type_${entry.key}');
      await _sharedPreferences.remove('wallet_group_icon_value_${entry.key}');
      await _sharedPreferences.remove('wallet_group_icon_color_${entry.key}');
      await _sharedPreferences.remove('wallet_group_icon_bg_enabled_${entry.key}');
    }
  }

  String _legacyGroupKey(WalletInfo walletInfo) {
    if (walletInfo.hashedWalletIdentifier != null &&
        walletInfo.hashedWalletIdentifier!.isNotEmpty) {
      return walletInfo.hashedWalletIdentifier!;
    }

    final address = walletInfo.parentAddress ?? walletInfo.address;
    if (address.isEmpty) {
      return '';
    }
    return address;
  }

  /// Resolves the key this wallet is (or, once grouped, will be) filed
  /// under in [walletGroups]:
  /// - If the wallet already belongs to a real, persisted group, that
  ///   group's immutable id is returned.
  /// - Otherwise, the legacy identifier (hashedWalletIdentifier, falling
  ///   back to parentAddress/address, falling back to the wallet's own id)
  ///   is returned. This is exactly the key [_backfillLegacyGroups] will use
  ///   as the group's id once/if this wallet ends up sharing it with
  ///   another wallet, so callers can safely use the returned key right away
  ///   (e.g. to tag sibling placeholder wallets before the real group row
  ///   exists yet) and keep using it afterwards.
  String resolveGroupKey(WalletInfo walletInfo) {
    if (walletInfo.groupId != null && walletInfo.groupId!.isNotEmpty) {
      return walletInfo.groupId!;
    }

    final legacy = _legacyGroupKey(walletInfo);
    return legacy.isNotEmpty ? legacy : walletInfo.id;
  }

  /// Adds a wallet to the in-memory view of its (already-persisted) group.
  /// This never creates a new persisted group: group membership ([WalletInfo.groupId])
  /// must already be set on the wallet itself.
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

    final persisted = await db.WalletGroup.get(groupKey);
    if (persisted == null) return;

    persisted.name = name;
    await persisted.save();

    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupKey);
    group?.groupName = name;
    _markGroupsChanged();
  }

  /// Sets a group's custom icon. Same single-row-update guarantee as [setGroupName].
  Future<void> setGroupIcon(String groupKey, WalletIcon icon) async {
    if (groupKey.isEmpty || icon.value.isEmpty) return;

    final persisted = await db.WalletGroup.get(groupKey);
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
    return group.wallets.length > 1 ? group.groupName : null;
  }

  WalletIcon? getGroupIcon(WalletInfo walletInfo) {
    final groupId = walletInfo.groupId;
    if (groupId == null || groupId.isEmpty) return null;

    final group = walletGroups.firstWhereOrNull((g) => g.groupKey == groupId);
    if (group == null || group.wallets.length <= 1) return null;
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



