import "dart:async";

import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/resource_manager.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:mobx/mobx.dart";

typedef WalletPool = ResourceManager<WalletKey, WalletBase>;
typedef WalletHold = ResourceHold<WalletBase>;

class WalletPoolService {
  WalletPoolService({
    required WalletPool pool,
    required AppStore appStore,
    required WalletLoadingService walletLoadingService,
  })  : _pool = pool,
        _appStore = appStore,
        _walletLoadingService = walletLoadingService;

  final WalletPool _pool;
  final AppStore _appStore;
  final WalletLoadingService _walletLoadingService;

  Future<void> _lastSwitch = Future.value();
  WalletHold? _activeHold;

  WalletBase get active => _appStore.wallet!;

  WalletKey? get _activeKey => _appStore.wallet?.key;

  Future<void> switchTo(WalletKey key, {Future<WalletBase> Function()? load}) =>
      _queue(() => _switchTo(key, load));

  Future<void> closeActive() => _queue(() async {
        final prev = _activeHold;
        _activeHold = null;
        runInAction(() => _appStore.wallet = null);

        await prev?.release();
      });

  Future<void> _queue(Future<void> Function() action) {
    final result = _lastSwitch.then((_) => action());
    _lastSwitch = result.catchError((Object _) {});
    return result;
  }

  Future<void> _switchTo(WalletKey key, Future<WalletBase> Function()? load) async {
    if (_activeKey == key) {
      return;
    }

    final next = await _pool.hold(key, load: load);
    final prev = _activeHold;
    _activeHold = next;


    // we still use appStore for backwards compatibility
    // we could also store the active wallet in this class, but only after every mobx dependency is removed
    runInAction(() => _appStore.wallet = next.resource);
    await _appStore.onWalletChanged(_appStore.wallet);

    if (prev != null) {
      unawaited(prev.release());
    }
  }

  // loads wallet, retrieves whatever info you need from it, closes wallet
  // auto-chooses the active wallet if that's what was passed, so you can pass the active wallet's wi as a fallback
  // ex. Future<PendingTransaction> createTransaction(List<Output> outputs, WalletInfo wi) => runWithWallet<PendingTransaction>(wi, (wallet)=>wallet.createTransaction(outputs))
  // do NOT use unawaited() inside runWithWallet!!! or expect HELL!!!!
  Future<T> runWithWallet<T>(WalletKey key, Future<T> Function(WalletBase) task) =>
      _pool.runWithResource(key, task);

  // gives you a held wallet for later release
  // when you're done with it you have to manually release() this object.
  // i recommend doing this in dispose() or close() and keeping these wallets to a single flow
  Future<WalletHold> hold(WalletKey key) => _pool.hold(key);

  Future<void> rename(WalletKey key, String newName, {String? password}) => _pool.runExclusive(
      key,
      () => _walletLoadingService.renameWallet(key.type, key.name, newName, password: password),);

  Future<void> remove(WalletKey key) => _pool.runExclusive(
      key, () => _walletLoadingService.walletServiceFactory(key.type).remove(key.name),);
}
