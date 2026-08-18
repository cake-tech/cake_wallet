import "dart:async";

import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";
import "package:mocktail/mocktail.dart";

class _MockWallet extends Mock implements WalletBase {}

class _FakeAppStore extends Fake implements AppStore {
  final _wallet = Observable<WalletBase?>(null);

  @override
  WalletBase? get wallet => _wallet.value;

  void setWallet(WalletBase? next) {
    runInAction(() => _wallet.value = next);
  }
}

void main() {
  late _FakeAppStore appStore;

  setUp(() {
    appStore = _FakeAppStore();
  });

  group("wallet getter", () {
    test("throws StateError when no wallet is active", () {
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);

      expect(() => service.wallet, throwsStateError);
    });

    test("returns the current wallet when set", () {
      final wallet = _MockWallet();
      appStore.setWallet(wallet);
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);

      expect(service.wallet, same(wallet));
    });
  });

  group("walletChanges stream", () {
    test("emits when the wallet transitions from null to a wallet", () async {
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);
      final received = <WalletBase>[];
      final sub = service.walletChanges.listen(received.add);
      addTearDown(sub.cancel);

      final wallet = _MockWallet();
      appStore.setWallet(wallet);
      await Future<void>.delayed(Duration.zero);

      expect(received, [same(wallet)]);
    });

    test("emits each subsequent wallet swap", () async {
      appStore.setWallet(_MockWallet());
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);
      final received = <WalletBase>[];
      final sub = service.walletChanges.listen(received.add);
      addTearDown(sub.cancel);

      final second = _MockWallet();
      final third = _MockWallet();
      appStore.setWallet(second);
      await Future<void>.delayed(Duration.zero);
      appStore.setWallet(third);
      await Future<void>.delayed(Duration.zero);

      expect(received, [same(second), same(third)]);
    });

    test("does NOT emit when the wallet transitions to null", () async {
      appStore.setWallet(_MockWallet());
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);
      final received = <WalletBase>[];
      final sub = service.walletChanges.listen(received.add);
      addTearDown(sub.cancel);

      appStore.setWallet(null);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test("does NOT emit synchronously for the initial wallet", () async {
      appStore.setWallet(_MockWallet());
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);
      final received = <WalletBase>[];
      final sub = service.walletChanges.listen(received.add);
      addTearDown(sub.cancel);

      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test("does NOT re-emit when the same wallet is assigned twice", () async {
      final wallet = _MockWallet();
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);
      final received = <WalletBase>[];
      final sub = service.walletChanges.listen(received.add);
      addTearDown(sub.cancel);

      appStore.setWallet(wallet);
      await Future<void>.delayed(Duration.zero);
      appStore.setWallet(wallet);
      await Future<void>.delayed(Duration.zero);

      expect(received, [same(wallet)]);
    });

    test("emits again when swapping to a different instance of the same class", () async {
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);
      final received = <WalletBase>[];
      final sub = service.walletChanges.listen(received.add);
      addTearDown(sub.cancel);

      final a = _MockWallet();
      final b = _MockWallet();
      appStore.setWallet(a);
      await Future<void>.delayed(Duration.zero);
      appStore.setWallet(b);
      await Future<void>.delayed(Duration.zero);

      expect(received, [same(a), same(b)]);
    });

    test(
      "cancelling one subscriber does not prevent another from receiving further events",
      () async {
        final service = ActiveWalletService(appStore);
        addTearDown(service.dispose);
        final a = <WalletBase>[];
        final b = <WalletBase>[];
        final subA = service.walletChanges.listen(a.add);
        final subB = service.walletChanges.listen(b.add);
        addTearDown(subB.cancel);

        appStore.setWallet(_MockWallet());
        await Future<void>.delayed(Duration.zero);
        await subA.cancel();
        final second = _MockWallet();
        appStore.setWallet(second);
        await Future<void>.delayed(Duration.zero);

        expect(a.length, 1);
        expect(b, [isA<WalletBase>(), same(second)]);
      },
    );

    test("is a broadcast stream — multiple subscribers each receive events", () async {
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);
      final a = <WalletBase>[];
      final b = <WalletBase>[];
      final subA = service.walletChanges.listen(a.add);
      final subB = service.walletChanges.listen(b.add);
      addTearDown(subA.cancel);
      addTearDown(subB.cancel);

      final wallet = _MockWallet();
      appStore.setWallet(wallet);
      await Future<void>.delayed(Duration.zero);

      expect(a, [same(wallet)]);
      expect(b, [same(wallet)]);
    });
  });

  group("dispose", () {
    test("closes the walletChanges stream and stops emitting", () async {
      final service = ActiveWalletService(appStore);
      final received = <WalletBase>[];
      final done = Completer<void>();
      final sub = service.walletChanges.listen(received.add, onDone: done.complete);

      await service.dispose();
      await done.future;

      expect(sub.isPaused, isFalse);
      await sub.cancel();

      appStore.setWallet(_MockWallet());
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test("stops reacting to appStore changes after dispose", () async {
      final service = ActiveWalletService(appStore);
      final received = <WalletBase>[];
      final sub = service.walletChanges.listen(received.add);
      addTearDown(sub.cancel);

      await service.dispose();
      appStore.setWallet(_MockWallet());
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test("throwing StateError on wallet getter carries the expected message", () {
      final service = ActiveWalletService(appStore);
      addTearDown(service.dispose);

      expect(
        () => service.wallet,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            "message",
            contains("No wallet is active yet"),
          ),
        ),
      );
    });
  });
}
