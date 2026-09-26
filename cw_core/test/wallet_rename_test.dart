import "dart:io";

import "package:cw_core/cake_hive.dart";
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/wallet_rename.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";

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

  test("rekeys unspent coins stored on CakeHive", () async {
    final dir = await Directory.systemTemp.createTemp("unspent_rekey");
    CakeHive.init(dir.path);
    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }

    final box = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
    final frozen = _coin("bitcoin_old", isFrozen: true);
    await box.add(frozen);

    expect(Hive.isBoxOpen(UnspentCoinsInfo.boxName), isFalse);

    await rekeyOpenUnspentCoins(oldWalletId: "bitcoin_old", newWalletId: "bitcoin_new");

    expect(frozen.walletId, "bitcoin_new");
    expect(frozen.isFrozen, isTrue);

    await box.close();
    await dir.delete(recursive: true);
  });
}
