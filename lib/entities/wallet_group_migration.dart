import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_group_db_entry.dart";
import "package:cw_core/wallet_info.dart";
import "package:uuid/uuid.dart";

Future<void> migrateLegacyWalletsToGroups() async {
  try {
    final groupIds = (await WalletGroupDbEntry.getAll()).map((g) => g.id).toSet();

    for (final wallet in await WalletInfo.getAll()) {
      if (!wallet.isReady) continue; // placeholders already have a group

      final id = wallet.groupId;
      if (id != null && id.isNotEmpty && groupIds.contains(id)) continue; // already grouped

      final groupId = (id != null && id.isNotEmpty) ? id : const Uuid().v4();
      final group = WalletGroupDbEntry.external(id: groupId)..name = wallet.name;
      await group.save();

      wallet.groupId = groupId;
      await wallet.save();
    }
  } catch (e, s) {
    printV("migrateLegacyWalletsToGroups failed: $e\n$s");
  }
}