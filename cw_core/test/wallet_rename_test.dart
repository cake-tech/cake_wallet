import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/wallet_rename.dart";
import "package:flutter_test/flutter_test.dart";

UnspentCoinsInfo _coin(String walletId, {required bool isFrozen}) => UnspentCoinsInfo(
      walletId: walletId,
      hash: "aa",
      isFrozen: isFrozen,
      isSending: false,
      noteRaw: "note",
      address: "bc1q",
      vout: 0,
      value: 1,
    );

void main() {
  test("does not sync the open wallet when rename failed", () {
    expect(shouldSyncOpenedWalletAfterRename(renameSucceeded: false), isFalse);
  });

  test("keeps frozen unspent coins on the new wallet id", () {
    final frozen = _coin("bitcoin_old", isFrozen: true);
    final other = _coin("bitcoin_other", isFrozen: false);

    final updated = rekeyUnspentCoinWalletIds(
      [frozen, other],
      oldWalletId: "bitcoin_old",
      newWalletId: "bitcoin_new",
    );

    expect(updated, [frozen]);
    expect(frozen.walletId, "bitcoin_new");
    expect(frozen.isFrozen, isTrue);
    expect(other.walletId, "bitcoin_other");
  });
}
