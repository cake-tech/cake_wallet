import "package:cake_wallet/entities/wallet_group_db_entry.dart";
import "package:cw_core/wallet_info.dart";

Future<String> groupNameForWallet(WalletInfo wallet) async {
  final groupId = wallet.groupId;
  if (groupId == null || groupId.isEmpty) return wallet.name;

  final groupName = (await WalletGroupDbEntry.get(groupId))?.name?.trim() ?? "";
  return groupName.isNotEmpty ? groupName : wallet.name;
}
