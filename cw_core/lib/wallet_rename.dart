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
