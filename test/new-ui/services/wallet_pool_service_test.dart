import "dart:async";

import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/new-ui/services/wallet_pool_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/resource_manager.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_service.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

typedef _AnyWallet = WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>;

typedef _AnyWalletService
    = WalletService<WalletCredentials, WalletCredentials, WalletCredentials, WalletCredentials>;

class _Wallet extends Fake implements _AnyWallet {
  _Wallet(this.key);

  @override
  final WalletKey key;

  int disposeCalls = 0;

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

class _AppStore extends Fake implements AppStore {
  final _wallet = Observable<_AnyWallet?>(null);

  @override
  _AnyWallet? get wallet => _wallet.value;

  @override
  set wallet(_AnyWallet? value) => _wallet.value = value;
}

class _ChainService extends Fake implements _AnyWalletService {
  _ChainService(this._calls);

  final List<String> _calls;

  @override
  Future<void> remove(String wallet) async => _calls.add("remove $wallet");
}

class _WalletLoadingService extends Fake implements WalletLoadingService {
  final List<String> calls = [];
  void Function()? onRename;

  @override
  Future<void> renameWallet(WalletType type, String name, String newName, {String? password}) async {
    onRename?.call();
    calls.add("rename $name -> $newName");
  }

  @override
  _AnyWalletService Function(WalletType) get walletServiceFactory => (_) => _ChainService(calls);
}

class _Harness {
  _Harness() {
    service = WalletPoolService(
      pool: WalletPool(loader: _load),
      appStore: appStore,
      walletLoadingService: walletLoadingService,
    );
  }

  final appStore = _AppStore();
  final walletLoadingService = _WalletLoadingService();
  late final WalletPoolService service;

  final List<WalletKey> loaded = [];
  final List<_Wallet> created = [];
  final Set<WalletKey> failing = {};
  final Map<WalletKey, Completer<void>> gates = {};

  Future<_AnyWallet> _load(WalletKey key) async {
    loaded.add(key);
    if (failing.remove(key)) throw StateError("cannot open ${key.name}");
    await gates[key]?.future;
    final wallet = _Wallet(key);
    created.add(wallet);
    return wallet;
  }
}

Future<void> pump([int turns = 8]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  const a = WalletKey("a", WalletType.bitcoin);
  const b = WalletKey("b", WalletType.bitcoin);

  test("switchTo publishes to appStore.wallet in an action that reactions see", () async {
    final h = _Harness();
    final seen = <_AnyWallet?>[];
    addTearDown(reaction((_) => h.appStore.wallet, seen.add).call);

    await h.service.switchTo(a);

    expect(h.appStore.wallet, same(h.created.single));
    expect(h.service.active, same(h.created.single));
    expect(seen, [h.created.single]);
  });

  test("the previous wallet is released only after the next one is published", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final first = h.created.single;

    int? disposeCallsAtPublish;
    addTearDown(
      reaction((_) => h.appStore.wallet, (_) => disposeCallsAtPublish = first.disposeCalls).call,
    );

    await h.service.switchTo(b);
    await pump();

    expect(disposeCallsAtPublish, 0, reason: "appStore.wallet must never point at a closed wallet");
    expect(h.appStore.wallet, same(h.created[1]));
    expect(first.disposeCalls, 1);
    expect(h.created[1].disposeCalls, 0);
  });

  test("switching to the active wallet keeps it and notifies nobody", () async {
    final h = _Harness();
    await h.service.switchTo(a);

    var notified = 0;
    addTearDown(reaction((_) => h.appStore.wallet, (_) => notified++).call);

    await h.service.switchTo(a);
    await pump();

    expect(h.loaded, [a]);
    expect(h.created.single.disposeCalls, 0);
    expect(notified, 0);
  });

  test("switching back to the active wallet while another switch is in flight isn't lost", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    h.gates[b] = Completer<void>();

    final toB = h.service.switchTo(b);
    final backToA = h.service.switchTo(a);
    await pump();

    h.gates[b]!.complete();
    await Future.wait([toB, backToA]);
    await pump();

    expect(h.appStore.wallet!.key, a, reason: "the second switch must still apply after the first lands");
    expect(h.loaded, [a, b, a]);
    expect(h.appStore.wallet, same(h.created[2]));
    expect(h.created[0].disposeCalls, 1);
    expect(h.created[1].disposeCalls, 1, reason: "b was released once a was back");
  });

  test("a failed switch leaves the active wallet in place and later switches still run", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final first = h.created.single;

    h.failing.add(b);
    await expectLater(h.service.switchTo(b), throwsA(isA<StateError>()));
    await pump();

    expect(h.appStore.wallet, same(first));
    expect(first.disposeCalls, 0);

    await h.service.switchTo(b);
    await pump();

    expect(h.appStore.wallet!.key, b);
    expect(first.disposeCalls, 1);
  });

  test("back to back switches run one after the other", () async {
    final h = _Harness();
    h.gates[a] = Completer<void>();

    final first = h.service.switchTo(a);
    final second = h.service.switchTo(b);
    await pump();

    expect(h.loaded, [a], reason: "b must wait for the switch to a to finish");

    h.gates[a]!.complete();
    await Future.wait([first, second]);
    await pump();

    expect(h.loaded, [a, b]);
    expect(h.appStore.wallet!.key, b);
    expect(h.created[0].disposeCalls, 1);
    expect(h.created[1].disposeCalls, 0);
  });

  test("runWithWallet on the active key reuses the active instance", () async {
    final h = _Harness();
    await h.service.switchTo(a);

    final used = await h.service.runWithWallet(a, (wallet) async => wallet);
    await pump();

    expect(used, same(h.created.single));
    expect(h.loaded, [a]);
    expect(h.created.single.disposeCalls, 0, reason: "the task leaving must not close the active wallet");
  });

  test("a task on the old wallet keeps it open across a switch", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final gate = Completer<void>();

    final task = h.service.runWithWallet(a, (_) => gate.future);
    await pump();

    await h.service.switchTo(b);
    await pump();

    expect(h.appStore.wallet!.key, b);
    expect(h.created[0].disposeCalls, 0, reason: "the task is still using it");

    gate.complete();
    await task;
    await pump();

    expect(h.created[0].disposeCalls, 1);
  });

  test("switching to a wallet a task already has open reuses that instance", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final gate = Completer<void>();
    _AnyWallet? fromTask;

    final task = h.service.runWithWallet(b, (wallet) async {
      fromTask = wallet;
      await gate.future;
    });
    await pump();

    await h.service.switchTo(b);

    expect(h.appStore.wallet, same(fromTask));
    expect(h.loaded, [a, b]);

    gate.complete();
    await task;
    await pump();

    expect(h.created[1].disposeCalls, 0, reason: "b is the active wallet now");
  });

  test("switchTo with load adopts a wallet opened elsewhere", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final created = _Wallet(b);

    await h.service.switchTo(b, load: () async => created);
    await pump();

    expect(h.appStore.wallet, same(created));
    expect(h.loaded, [a], reason: "the pool's own loader must not run for b");
    expect(h.created.single.disposeCalls, 1);

    await h.service.switchTo(a);
    await pump();

    expect(created.disposeCalls, 1, reason: "the adopted wallet is pooled like any other");
  });

  test("rename and remove refuse the active wallet", () async {
    final h = _Harness();
    await h.service.switchTo(a);

    await expectLater(h.service.rename(a, "c"), throwsA(isA<ResourceInUseException>()));
    await expectLater(h.service.remove(a), throwsA(isA<ResourceInUseException>()));

    expect(h.walletLoadingService.calls, isEmpty);
    expect(h.created.single.disposeCalls, 0);
  });

  test("rename and remove refuse a wallet a task is using", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final gate = Completer<void>();

    final task = h.service.runWithWallet(b, (_) => gate.future);
    await pump();

    await expectLater(h.service.rename(b, "c"), throwsA(isA<ResourceInUseException>()));
    await expectLater(h.service.remove(b), throwsA(isA<ResourceInUseException>()));
    expect(h.walletLoadingService.calls, isEmpty);

    gate.complete();
    await task;
  });

  test("rename and remove go through for a wallet that isn't open", () async {
    final h = _Harness();
    await h.service.switchTo(a);

    await h.service.rename(b, "c");
    await h.service.remove(b);

    expect(h.walletLoadingService.calls, ["rename b -> c", "remove b"]);
    expect(h.loaded, [a], reason: "neither may open the wallet");
  });

  test("the wallet you just switched away from is closed before it is renamed", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    await h.service.switchTo(b);

    int? disposeCallsAtRename;
    h.walletLoadingService.onRename = () => disposeCallsAtRename = h.created[0].disposeCalls;

    await h.service.rename(a, "c");

    expect(disposeCallsAtRename, 1);
  });

  test("closeActive unpublishes the active wallet and waits for it to close", () async {
    final h = _Harness();
    await h.service.switchTo(a);

    final seen = <_AnyWallet?>[];
    addTearDown(reaction((_) => h.appStore.wallet, seen.add).call);

    await h.service.closeActive();

    expect(h.appStore.wallet, isNull);
    expect(seen, [null]);
    expect(h.created.single.disposeCalls, 1, reason: "closed by the time closeActive returns");
  });

  test("after closeActive the same key opens a fresh wallet", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final wiped = h.created.single;
    await h.service.closeActive();

    final restored = _Wallet(a);
    await h.service.switchTo(a, load: () async => restored);
    await pump();

    expect(h.appStore.wallet, same(restored), reason: "the closed instance must not come back");
    expect(wiped.disposeCalls, 1, reason: "closed exactly once");
    expect(restored.disposeCalls, 0);
  });

  test("closeActive with nothing active does nothing", () async {
    final h = _Harness();

    await h.service.closeActive();

    expect(h.appStore.wallet, isNull);
    expect(h.loaded, isEmpty);
  });

  test("a hold keeps a wallet open after switching away from it", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final hold = await h.service.hold(a);

    await h.service.switchTo(b);
    await pump();
    expect(hold.resource, same(h.created[0]));
    expect(h.created[0].disposeCalls, 0, reason: "the flow still holds it");

    await hold.release();
    expect(h.created[0].disposeCalls, 1);
  });

  test("switching to a held wallet reuses the held instance, and releasing the hold keeps it active", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final hold = await h.service.hold(b);

    await h.service.switchTo(b);
    expect(h.appStore.wallet, same(hold.resource));
    expect(h.loaded, [a, b]);

    await hold.release();
    await pump();
    expect(h.created[1].disposeCalls, 0, reason: "b is the active wallet now");
  });

  test("a held wallet can't be renamed or removed", () async {
    final h = _Harness();
    await h.service.switchTo(a);
    final hold = await h.service.hold(b);

    await expectLater(h.service.rename(b, "c"), throwsA(isA<ResourceInUseException>()));
    await expectLater(h.service.remove(b), throwsA(isA<ResourceInUseException>()));

    await hold.release();
    await h.service.remove(b);
    expect(h.walletLoadingService.calls, ["remove b"]);
  });
}
