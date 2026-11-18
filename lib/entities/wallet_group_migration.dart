import "package:cake_wallet/entities/new_ui_entities/wallet_icon.dart";
import "package:cake_wallet/entities/wallet_group_db_entry.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:uuid/uuid.dart";

/// Gives every wallet a persisted `walletGroup` row.
///
/// Legacy groups were never persisted: wallets were grouped at runtime by
/// `hashedWalletIdentifier ?? parentAddress ?? address`, and custom group names lived in
/// SharedPreferences under `wallet_group_name_<key>`.
///
/// For each legacy group:
/// - wallets that can't share a group (hardware, or failing the add-to-group picker rule,
///   see [canShareWalletGroup]) each get their own single-wallet group;
/// - of duplicate types only the oldest wallet stays, the others get their own group;
/// - if 2+ wallets remain they form one group (keeping the custom legacy name), else single.
///
/// Each group is written in one transaction (group row + its wallets' `groupId`), which also
/// clears the wallets' `hashedWalletIdentifier`. Once every group of a legacy group is
/// written, its `wallet_group_name_<key>` preference is removed.
///
/// Idempotent: wallets already pointing to an existing group row are skipped, so it is
/// safe to run on every (foreground) startup and after a backup import.
///
/// Writes the DB directly, so it can run before DI setup.
///
/// SECURITY: in debug builds hashedWalletIdentifier (and the legacy wallet_group_name_* pref
/// keys) may contain the plaintext mnemonic. Never log legacy keys.
Future<void> migrateLegacyWalletsToGroups(
  SharedPreferences prefs, {
  @visibleForTesting void Function(List<WalletInfo> wallets)? beforeGroupCommit,
}) async {
  final existingGroupIds = {for (final g in await WalletGroupDbEntry.getAll()) g.id};
  final takenNames = await _takenGroupNames();

  // 1. Collect wallets that still need a group, bucketed by main's legacy group key.
  final legacyBuckets = <String, List<WalletInfo>>{};
  final singles = <WalletInfo>[];

  for (final wallet in await WalletInfo.getAll()) {
    final currentId = wallet.groupId;
    final hasValidGroup =
        currentId != null && currentId.isNotEmpty && existingGroupIds.contains(currentId);
    if (hasValidGroup) continue; // already migrated

    final legacyKey = _legacyGroupKey(wallet);
    if (legacyKey == null) {
      singles.add(wallet);
    } else {
      legacyBuckets.putIfAbsent(legacyKey, () => []).add(wallet);
    }
  }

  if (legacyBuckets.isEmpty && singles.isEmpty) return; // nothing to migrate

  // 2. Keep the shareable wallets of each legacy group together; split off the rest.
  final plans = <_GroupPlan>[];
  final pendingPerLegacyKey = <String, int>{};
  var keptCount = 0;
  var splitOffCount = 0;

  for (final MapEntry(key: legacyKey, value: wallets) in legacyBuckets.entries) {
    final shared = <WalletInfo>[];
    final splitOff = <WalletInfo>[];
    final seenTypes = <WalletType>{};

    final byAge = [...wallets]..sort((a, b) => a.date.compareTo(b.date));
    for (final wallet in byAge) {
      final canShare = wallet.hardwareWalletType == null && await canShareWalletGroup(wallet);
      if (canShare && seenTypes.add(wallet.type)) {
        shared.add(wallet);
      } else {
        splitOff.add(wallet);
      }
    }

    final keepGroup = shared.length >= 2;
    if (keepGroup) {
      plans.add(_GroupPlan(shared, legacyKey));
      keptCount++;
      splitOffCount += splitOff.length;
    } else {
      splitOff.insertAll(0, shared);
    }
    plans.addAll(splitOff.map((w) => _GroupPlan([w], legacyKey)));
    pendingPerLegacyKey[legacyKey] = (keepGroup ? 1 : 0) + splitOff.length;
  }

  plans.addAll(singles.map((w) => _GroupPlan([w], null)));

  // 3. Create the rows and attach the wallets, one transaction per group.
  var createdCount = 0;
  for (final plan in plans) {
    final wallets = plan.wallets;
    final legacyKey = plan.legacyKey;
    try {
      // main only showed custom group names for multi-wallet groups.
      final customName = wallets.length > 1 && legacyKey != null
          ? prefs.getString(_legacyGroupNamePrefKey(legacyKey))
          : null;
      final entry = _newGroupEntry(wallets, takenNames, customName: customName);

      await db!.transaction((txn) async {
        await txn.insert(WalletGroupDbEntry.tableName, entry.toJson());
        for (final wallet in wallets) {
          await txn.update(
            WalletInfo.tableName,
            {"groupId": entry.id, "hashedWalletIdentifier": null},
            where: "${WalletInfo.selfIdColumn} = ?",
            whereArgs: [wallet.internalId],
          );
        }
        beforeGroupCommit?.call(wallets);
      });

      for (final wallet in wallets) {
        wallet.groupId = entry.id;
        wallet.hashedWalletIdentifier = null;
      }
      takenNames.add(entry.name!.toLowerCase());
      createdCount++;

      if (legacyKey != null) {
        final pending = pendingPerLegacyKey[legacyKey]! - 1;
        pendingPerLegacyKey[legacyKey] = pending;
        if (pending == 0) await prefs.remove(_legacyGroupNamePrefKey(legacyKey));
      }
    } catch (e) {
      _log("failed to create a group of ${wallets.length} wallets: ${e.runtimeType}");
    }
  }

  _log("created $createdCount/${plans.length} groups "
      "(kept $keptCount legacy groups, split off $splitOffCount wallets)");
}

/// Puts a newly created [wallet] into a group and sets `wallet.groupId`.
///
/// Joins [joinGroupId] if that group row exists, otherwise creates a new single-wallet
/// group named after the wallet. Does not save the wallet; the caller does.
Future<String> assignWalletGroup(WalletInfo wallet, {String? joinGroupId}) async {
  if (joinGroupId != null &&
      joinGroupId.isNotEmpty &&
      await WalletGroupDbEntry.get(joinGroupId) != null) {
    wallet.groupId = joinGroupId;
    return joinGroupId;
  }

  final entry = _newGroupEntry([wallet], await _takenGroupNames());
  await entry.save();
  wallet.groupId = entry.id;
  return entry.id;
}

class _GroupPlan {
  _GroupPlan(this.wallets, this.legacyKey);

  final List<WalletInfo> wallets;

  /// May contain the plaintext mnemonic — never log it.
  final String? legacyKey;
}

void _log(String message) => printV("[WalletGroupMigration] $message");

// ---- Legacy (main) grouping --------------------------------------------------

/// Same key main's WalletManager used. null = never part of a shared group.
/// May contain the plaintext mnemonic — do not log or persist it anywhere new.
String? _legacyGroupKey(WalletInfo wallet) {
  final hash = wallet.hashedWalletIdentifier;
  if (hash != null && hash.isNotEmpty) return hash;

  final address = wallet.parentAddress ?? wallet.address;
  return address.isEmpty ? null : address;
}

String _legacyGroupNamePrefKey(String legacyKey) => "wallet_group_name_$legacyKey";

// ---- Naming & icons ----------------------------------------------------------

Future<Set<String>> _takenGroupNames() async => (await WalletGroupDbEntry.getAll())
    .map((g) => (g.name ?? "").trim().toLowerCase())
    .where((name) => name.isNotEmpty)
    .toSet();

/// A new (unsaved) group row for [wallets] with a unique name and the default icon.
WalletGroupDbEntry _newGroupEntry(
  List<WalletInfo> wallets,
  Set<String> takenNames, {
  String? customName,
}) {
  final name = _uniqueName(_groupName(wallets, customName?.trim()), takenNames);
  final icon = wallets.length > 1 ? WalletIcon.defaultIcon : _coinIcon(wallets.first.type);

  return WalletGroupDbEntry.external(
    id: const Uuid().v4(),
    name: name,
    iconType: icon.type.name,
    iconValue: icon.value,
    iconColor: icon.colorIndex.toString(),
    iconBg: icon.backgroundEnabled.toString(),
  );
}

String _groupName(List<WalletInfo> wallets, String? customName) {
  if (customName != null && customName.isNotEmpty) return customName;

  final source = _nameSource(wallets);
  final ownName = source.name.trim();
  return ownName.isNotEmpty ? ownName : walletTypeToDisplayName(source.type);
}

/// Oldest wallet with a user-given name (not just the network name), else the oldest wallet.
WalletInfo _nameSource(List<WalletInfo> wallets) {
  final sorted = [...wallets]..sort((a, b) => a.date.compareTo(b.date));
  return sorted.firstWhere(
    (w) => w.name.trim().isNotEmpty && w.name.trim() != walletTypeToDisplayName(w.type),
    orElse: () => sorted.first,
  );
}

/// "Main", "Main 2", "Main 3", … (case-insensitive).
String _uniqueName(String base, Set<String> takenLower) {
  if (!takenLower.contains(base.toLowerCase())) return base;
  for (var i = 2;; i++) {
    final candidate = "$base $i";
    if (!takenLower.contains(candidate.toLowerCase())) return candidate;
  }
}

WalletIcon _coinIcon(WalletType type) => WalletIcon(
      type: WalletIconType.crypto,
      value: type.name,
      colorIndex: 0,
      backgroundEnabled: false,
    );
