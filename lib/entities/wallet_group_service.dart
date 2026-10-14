import "dart:async";

import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cw_core/wallet_group_db_entry.dart";
import "package:cw_core/wallet_info.dart";
import "package:rxdart/rxdart.dart";

class WalletGroupService {
  final _subject = BehaviorSubject<List<WalletGroup>>.seeded(const []);

  Future<void> _lastUpdate = Future.value();

  List<WalletGroup> get groups => _subject.value;

  Stream<List<WalletGroup>> watch() => _subject.stream;

  Future<List<WalletGroup>> getAllGroups() async => [
        for (final g in await WalletGroupDbEntry.getAll())
          WalletGroup(g.id, groupName: g.name, icon: _iconFromPersisted(g)),
      ];

  Future<bool> isGroupNameTaken(String name, {String? excludeGroupKey}) =>
      WalletGroupDbEntry.nameExists(name.trim(), excludeId: excludeGroupKey);

  Future<bool> groupNameExists(String name) => isGroupNameTaken(name);

  String resolveGroupKey(WalletInfo walletInfo) {
    final groupId = walletInfo.groupId;
    if (groupId != null && groupId.isNotEmpty) return groupId;
    return walletInfo.id;
  }

  List<WalletInfo> getWalletsInGroup(String groupKey) => _find(groupKey)?.wallets ?? const [];

  String? getGroupName(WalletInfo walletInfo) => _persistedGroupOf(walletInfo)?.groupName;

  WalletIcon? getGroupIcon(WalletInfo walletInfo) => _persistedGroupOf(walletInfo)?.icon;

  Future<void> createWalletGroup(String groupId, {String? name, WalletIcon? icon}) =>
      WalletGroupDbEntry.external(
        id: groupId,
        name: name?.trim(),
        iconType: icon?.type.name,
        iconValue: icon?.value,
        iconColor: icon?.colorIndex.toString(),
        iconBg: icon?.backgroundEnabled.toString(),
      ).save();

  Future<void> setGroupIdForWalletInfo(WalletInfo walletInfo, String groupId) async {
    walletInfo.groupId = groupId;
    await walletInfo.save();
  }

  Future<void> setGroupName(String groupKey, String name) async {
    final trimmed = name.trim();
    if (groupKey.isEmpty || trimmed.isEmpty) {
      throw ArgumentError("setGroupName: empty groupKey or name");
    }

    final updated = await WalletGroupDbEntry.updateName(groupKey, trimmed);
    if (updated == 0) {
      throw Exception("setGroupName: no group row for id $groupKey");
    }

    _replaceGroup(groupKey, (g) => g.copyWith(groupName: trimmed));
  }

  Future<void> setGroupIcon(String groupKey, WalletIcon icon) async {
    if (groupKey.isEmpty) throw ArgumentError("setGroupIcon: empty groupKey");

    final updated = await WalletGroupDbEntry.updateIcon(
      groupKey,
      iconType: icon.type.name,
      iconValue: icon.value,
      iconColor: icon.colorIndex.toString(),
      iconBg: icon.backgroundEnabled.toString(),
    );
    if (updated == 0) {
      throw Exception("setGroupIcon: no group row for id $groupKey");
    }

    _replaceGroup(groupKey, (g) => g.copyWith(icon: icon));
  }

  Future<void> setGroupIconForWallet(WalletInfo walletInfo, WalletIcon icon) async {
    final groupId = walletInfo.groupId;
    if (groupId == null || groupId.isEmpty) return;
    await setGroupIcon(groupId, icon);
  }

  Future<void> deleteGroupIfEmpty(String groupKey) async {
    final stillUsed = (await WalletInfo.getAll()).any((w) => w.groupId == groupKey);
    if (!stillUsed) await WalletGroupDbEntry.delete(groupKey);
  }

  Future<void> updateWalletGroups() async {
    final waitFor = _lastUpdate;
    final done = Completer<void>();
    _lastUpdate = done.future;

    await waitFor;

    try {
      final allWallets = await WalletInfo.getAll();
      final persisted = {for (final g in await WalletGroupDbEntry.getAll()) g.id: g};
      _emit(_buildGroups(allWallets, persisted));
    } finally {
      done.complete();
    }
  }

  void addWallet(WalletInfo walletInfo) {
    final key = resolveGroupKey(walletInfo);
    final existing = _find(key);

    if (existing == null) {
      _emit([
        ...groups,
        WalletGroup(key, wallets: [walletInfo])
      ]);
      return;
    }
    if (existing.wallets.contains(walletInfo)) return;

    _replaceGroup(key, (g) => g.copyWith(wallets: [...g.wallets, walletInfo]));
  }

  void removeWallet(WalletInfo walletInfo) {
    final key = resolveGroupKey(walletInfo);
    final existing = _find(key);
    if (existing == null) return;

    final remaining = existing.wallets.where((w) => w.id != walletInfo.id).toList();
    if (remaining.isEmpty) {
      _emit(groups.where((g) => g.groupKey != key).toList());
    } else {
      _replaceGroup(key, (g) => g.copyWith(wallets: remaining));
    }
  }

  void _emit(List<WalletGroup> next) => _subject.add(List.unmodifiable(next));

  void _replaceGroup(String groupKey, WalletGroup Function(WalletGroup) change) {
    if (_find(groupKey) == null) return;
    _emit([for (final g in groups) g.groupKey == groupKey ? change(g) : g]);
  }

  WalletGroup? _find(String groupKey) {
    for (final g in groups) {
      if (g.groupKey == groupKey) return g;
    }
    return null;
  }

  WalletGroup? _persistedGroupOf(WalletInfo walletInfo) {
    final groupId = walletInfo.groupId;
    if (groupId == null || groupId.isEmpty) return null;
    return _find(groupId);
  }

  List<WalletGroup> _buildGroups(
    List<WalletInfo> allWallets,
    Map<String, WalletGroupDbEntry> persisted,
  ) {
    final byGroupId = <String, List<WalletInfo>>{};
    final ungrouped = <WalletInfo>[];

    for (final walletInfo in allWallets) {
      final groupId = walletInfo.groupId;
      if (groupId != null && groupId.isNotEmpty && persisted.containsKey(groupId)) {
        byGroupId.putIfAbsent(groupId, () => []).add(walletInfo);
      } else {
        ungrouped.add(walletInfo);
      }
    }

    return [
      for (final entry in byGroupId.entries)
        WalletGroup(
          entry.key,
          wallets: entry.value,
          groupName: persisted[entry.key]!.name,
          icon: _iconFromPersisted(persisted[entry.key]!),
        ),
      for (final walletInfo in ungrouped)
        WalletGroup(resolveGroupKey(walletInfo), wallets: [walletInfo]),
    ];
  }

  WalletIcon? _iconFromPersisted(WalletGroupDbEntry persisted) {
    final typeName = persisted.iconType;
    final value = persisted.iconValue;
    if (typeName == null || value == null) return null;

    final type = WalletIconType.values.asNameMap()[typeName];
    if (type == null) return null;

    final colorIndex = int.tryParse(persisted.iconColor ?? "") ?? 0;
    final backgroundEnabled = persisted.iconBg != "false";

    return WalletIcon(
      type: type,
      value: value,
      colorIndex: colorIndex,
      backgroundEnabled: backgroundEnabled,
    );
  }
}
