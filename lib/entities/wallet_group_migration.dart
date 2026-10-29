import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_group_db_entry.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:uuid/uuid.dart";

/// Gives every ready wallet a persisted `walletGroup` row.
///
/// Legacy (main) groups were never persisted: wallets were grouped at runtime by
/// `hashedWalletIdentifier ?? parentAddress ?? address`, and custom group names lived in
/// SharedPreferences under `wallet_group_name_<key>`.
///
/// A legacy group is kept together only if it is a valid omnichain group:
/// 2+ wallets, all BIP39-derived, no hardware wallets, no duplicate wallet types.
/// Every other wallet becomes its own single-wallet group.
///
/// Idempotent: wallets already pointing to an existing group row are skipped, so it is
/// safe to run on every (foreground) startup and after a backup import.
///
/// [keepLegacyGroups] = false puts every migrated wallet in its own group
/// (used after a backup import).
///
/// Writes the DB directly (no WalletGroupService), so it can run before DI setup.
/// Call `WalletGroupService.updateWalletGroups()` afterwards if the service is live.
///
/// SECURITY: on main, `hashedWalletIdentifier` contains the plaintext mnemonic, and so do
/// the `wallet_group_name_<key>` preference keys. Never log legacy keys.
Future<void> migrateLegacyWalletsToGroups(
    SharedPreferences prefs, {
      bool keepLegacyGroups = true,
    }) async {
  final existingGroups = {for (final g in await WalletGroupDbEntry.getAll()) g.id: g};
  final takenNames = existingGroups.values
      .map((g) => (g.name ?? "").trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();

  // 1. Collect wallets that still need a group, bucketed by main's legacy group key.
  final legacyBuckets = <String, List<WalletInfo>>{};
  final singles = <WalletInfo>[];

  for (final wallet in await WalletInfo.getAll()) {
    if (!wallet.isReady) continue; // placeholders already belong to a group

    final currentId = wallet.groupId;
    final hasValidGroup =
        currentId != null && currentId.isNotEmpty && existingGroups.containsKey(currentId);
    if (hasValidGroup) continue; // already migrated

    final legacyKey = keepLegacyGroups ? _legacyGroupKey(wallet) : null;
    if (legacyKey == null) {
      singles.add(wallet);
    } else {
      legacyBuckets.putIfAbsent(legacyKey, () => []).add(wallet);
    }
  }

  if (legacyBuckets.isEmpty && singles.isEmpty) return; // nothing to migrate

  // 2. Keep only clean omnichain groups together; split everything else.
  final groupsToCreate = <String, List<WalletInfo>>{}; // groupId -> wallets
  final legacyKeyByGroupId = <String, String>{};
  var keptCount = 0;
  var splitCount = 0;

  for (final MapEntry(key: legacyKey, value: wallets) in legacyBuckets.entries) {
    final splitReason = await _splitReason(wallets);
    if (splitReason == null) {
      final groupId = const Uuid().v4();
      groupsToCreate[groupId] = wallets;
      legacyKeyByGroupId[groupId] = legacyKey;
      keptCount++;
    } else {
      singles.addAll(wallets);
      if (wallets.length > 1) {
        splitCount++;
        _log("split legacy group of ${wallets.length} wallets: $splitReason");
      }
    }
  }

  for (final wallet in singles) {
    groupsToCreate[const Uuid().v4()] = [wallet];
  }

  // 3. Create the rows and attach the wallets.
  var createdCount = 0;
  for (final MapEntry(key: groupId, value: wallets) in groupsToCreate.entries) {
    try {
      final legacyKey = legacyKeyByGroupId[groupId];
      final name = _uniqueName(_groupName(wallets, legacyKey, prefs), takenNames);
      takenNames.add(name.toLowerCase());

      final icon = wallets.length > 1 ? WalletIcon.defaultIcon : _coinIcon(wallets.first.type);

      await WalletGroupDbEntry.external(
        id: groupId,
        name: name,
        iconType: icon.type.name,
        iconValue: icon.value,
        iconColor: icon.colorIndex.toString(),
        iconBg: icon.backgroundEnabled.toString(),
      ).save();

      for (final wallet in wallets) {
        wallet.groupId = groupId;
        // TODO(security): main stored the plaintext mnemonic in hashedWalletIdentifier.
        //  Clear it here once the team confirms nothing else reads it.
        await wallet.save();
      }

      createdCount++;
    } catch (e, s) {
      _log("failed to create a group of ${wallets.length} wallets: $e\n$s");
    }
  }

  // 4. Drop main's group-name preferences (their keys contain the legacy key) for every
  //    legacy bucket whose wallets are now all grouped — kept or split.
  //    Done last, so a failed group can be retried on the next launch with its name.
  for (final MapEntry(key: legacyKey, value: wallets) in legacyBuckets.entries) {
    final allGrouped = wallets.every((w) => (w.groupId ?? "").isNotEmpty);
    if (allGrouped) {
      await prefs.remove(_legacyGroupNamePrefKey(legacyKey));
    }
  }

  _log("created $createdCount/${groupsToCreate.length} groups "
      "(kept $keptCount legacy groups, split $splitCount)");
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

// ---- Omnichain compatibility -------------------------------------------------

/// null = the wallets may stay together; otherwise why the group is split.
/// The reason only mentions wallet types, never names or keys.
Future<String?> _splitReason(List<WalletInfo> wallets) async {
  if (wallets.length < 2) return "single wallet";

  final types = <WalletType>{};
  for (final wallet in wallets) {
    if (!types.add(wallet.type)) return "duplicate type ${wallet.type.name}";
    if (!isBIP39Wallet(wallet.type)) return "${wallet.type.name} is not a BIP39 type";
    if (wallet.hardwareWalletType != null) return "${wallet.type.name} is a hardware wallet";

    // These types are always BIP39 in Cake, and often don't store their derivation type.
    if (alwaysBip39Types.contains(wallet.type)) continue;

    final derivation = await wallet.getDerivationInfo();
    if (derivation.derivationType != DerivationType.bip39) {
      return "${wallet.type.name} derivationType=${derivation.derivationType?.name}";
    }
  }
  return null;
}

// ---- Naming & icons ----------------------------------------------------------

String _groupName(List<WalletInfo> wallets, String? legacyKey, SharedPreferences prefs) {
  // main only showed custom group names for multi-wallet groups.
  if (wallets.length > 1 && legacyKey != null) {
    final customName = prefs.getString(_legacyGroupNamePrefKey(legacyKey))?.trim();
    if (customName != null && customName.isNotEmpty) return customName;
  }

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