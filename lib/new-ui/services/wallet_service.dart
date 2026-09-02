

import "dart:async";
import "package:cw_core/resource_manager.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";

typedef WalletManager = ResourceManager<WalletKey, WalletBase>;

class WalletService {
  WalletService({required WalletManager manager}) : _manager = manager;

  final WalletManager _manager;

  late WalletBase _active;
  WalletBase get active => _active;

  Future<WalletBase> _load(WalletInfo wi) async {
    //TODO
    throw UnimplementedError();
  }

  Future<void> switchTo(WalletInfo wi) async {
    final wallet = await _load(wi);

    // active wallets should start sync automatically.
    // however, we don't need to wait for it to start syncing to use other features, hence unawaited
    unawaited(wallet.startSync());

    final prev = _active;
    unawaited(prev.close());

    _active = wallet;
  }

  // loads wallet, retrieves whatever info you need from it, closes wallet
  // auto-chooses the active wallet if that's what was passed, so you can pass the active wallet's wi as a fallback
  // ex. Future<PendingTransaction> createTransaction(List<Output> outputs, WalletInfo wi) => runWithWallet<PendingTransaction>(wi, (wallet)=>wallet.createTransaction(outputs))
  // do NOT use unawaited() inside runWithWallet!!! or expect HELL!!!!
  Future<T> runWithWallet<T>(WalletKey key, Future<T> Function(WalletBase) task) async {
    if(key == active.key) {
      return task(active);
    } else {
      return _manager.runWithResource(key, task);
    }
  }
}