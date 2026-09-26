import "package:cw_core/cake_hive.dart";
import "package:cw_core/unspent_coins_info.dart";

bool shouldSyncOpenedWalletAfterRename({required bool renameSucceeded}) => renameSucceeded;

List<UnspentCoinsInfo> rekeyUnspentCoinWalletIds(
  Iterable<UnspentCoinsInfo> coins, {
  required String oldWalletId,
  required String newWalletId,
}) {
  if (oldWalletId == newWalletId) {
    return const [];
  }

  final updated = <UnspentCoinsInfo>[];
  for (final coin in coins) {
    if (coin.walletId != oldWalletId) {
      continue;
    }

    coin.walletId = newWalletId;
    updated.add(coin);
  }

  return updated;
}

Future<void> rekeyOpenUnspentCoins({
  required String oldWalletId,
  required String newWalletId,
}) async {
  if (!CakeHive.isBoxOpen(UnspentCoinsInfo.boxName)) {
    return;
  }

  final box = CakeHive.box<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
  final updated = rekeyUnspentCoinWalletIds(
    box.values,
    oldWalletId: oldWalletId,
    newWalletId: newWalletId,
  );
  for (final coin in updated) {
    await coin.save();
  }
}
