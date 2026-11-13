import "dart:async";

import "package:cake_wallet/core/services/wallet_group_service.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_entry.dart";
import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_state.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:rxdart/rxdart.dart";

class _MockGroupService extends Mock implements WalletGroupService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

WalletInfo _wallet(String id, WalletType type, String groupId, {bool isReady = true}) =>
    WalletInfo.external(
      id: id,
      name: "wallet $id",
      type: type,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "addr_$id",
      groupId: groupId,
      isReady: isReady,
    );

void main() {
  setUpAll(() {
    S.current = const S();
    registerFallbackValue(_wallet("fallback", WalletType.bitcoin, "fallback"));
  });

  final btc = _wallet("btc", WalletType.bitcoin, "g1");
  final xmr = _wallet("xmr", WalletType.monero, "g1");
  final placeholder = _wallet("eth", WalletType.ethereum, "g1", isReady: false);
  final ltc = _wallet("ltc", WalletType.litecoin, "g2");

  List<WalletGroup> groupsNamed(String g1Name) => [
        WalletGroup("g1", wallets: [btc, xmr, placeholder], groupName: g1Name),
        WalletGroup("g2", wallets: [ltc], groupName: "Other"),
      ];

  late BehaviorSubject<List<WalletGroup>> subject;
  late _MockGroupService service;
  late _MockAppStore appStore;
  late int updateCalls;
  late Map<String, int> loadCalls;
  late Map<String, Completer<void>> gates;

  Future<List<WalletContactEntry>> loader(WalletInfo info) async {
    loadCalls[info.id] = (loadCalls[info.id] ?? 0) + 1;
    await gates[info.id]?.future;
    final currency = switch (info.type) {
      WalletType.monero => CryptoCurrency.xmr,
      WalletType.litecoin => CryptoCurrency.ltc,
      _ => CryptoCurrency.btc,
    };
    return [
      WalletContactEntry(
        walletId: info.id,
        walletName: info.name,
        walletType: info.type,
        address: "addr_${info.id}_${loadCalls[info.id]}",
        currency: currency,
        label: "Active",
        displayLabel: "Active",
      ),
    ];
  }

  void openWallet(WalletInfo info) {
    final wallet = _MockWallet();
    when(() => wallet.walletInfo).thenReturn(info);
    when(() => appStore.wallet).thenReturn(wallet);
  }

  WalletContactsCubit createCubit({CryptoCurrency? currency}) => WalletContactsCubit(
        groupService: service,
        appStore: appStore,
        currencyFilter: currency,
        loadEntries: loader,
      );

  setUp(() {
    subject = BehaviorSubject.seeded(groupsNamed("My Wallet"));
    updateCalls = 0;
    loadCalls = {};
    gates = {};

    service = _MockGroupService();
    when(() => service.groups).thenAnswer((_) => subject.value);
    when(() => service.watch()).thenAnswer((_) => subject.stream);
    when(() => service.updateWalletGroups()).thenAnswer((_) async {
      updateCalls++;
      subject.add(subject.value);
    });
    when(() => service.resolveGroupKey(any())).thenAnswer((invocation) {
      final info = invocation.positionalArguments.first as WalletInfo;
      return info.groupId ?? info.id;
    });

    appStore = _MockAppStore();
    openWallet(btc);
  });

  tearDown(() => subject.close());

  test("load() emits loading, then the groups with the current one first", () async {
    final cubit = createCubit();
    final states = <WalletContactsState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.load();
    await pumpEventQueue();

    expect(
        states.map((s) => s.status), [WalletContactsStatus.loading, WalletContactsStatus.loaded]);
    final state = cubit.state;
    expect(state.currentGroupId, "g1");
    expect(state.currentGroup!.name, "My Wallet");
    expect(state.currentGroup!.networkContacts.map((c) => c.walletType),
        [WalletType.bitcoin, WalletType.monero]);
    expect(state.otherGroups.map((g) => g.groupId), ["g2"]);
    // Placeholders are never read.
    expect(loadCalls, {"btc": 1, "xmr": 1, "ltc": 1});

    await sub.cancel();
    await cubit.close();
  });

  test("a group rename only re-maps cached addresses", () async {
    final cubit = createCubit();
    await cubit.load();

    subject.add(groupsNamed("Renamed"));
    await pumpEventQueue();

    expect(cubit.state.currentGroup!.name, "Renamed");
    expect(cubit.state.currentGroup!.contacts.first.name, "Renamed · Bitcoin (Active)");
    expect(loadCalls, {"btc": 1, "xmr": 1, "ltc": 1});
    await cubit.close();
  });

  test("a wallet switch changes the current group without re-reading addresses", () async {
    final cubit = createCubit();
    await cubit.load();

    openWallet(ltc);
    subject.add(groupsNamed("My Wallet"));
    await pumpEventQueue();

    expect(cubit.state.currentGroupId, "g2");
    expect(cubit.state.groups.first.groupId, "g2");
    expect(loadCalls, {"btc": 1, "xmr": 1, "ltc": 1});
    await cubit.close();
  });

  test("identical group lists don't emit a new state", () async {
    final cubit = createCubit();
    await cubit.load();
    final states = <WalletContactsState>[];
    final sub = cubit.stream.listen(states.add);

    subject.add(groupsNamed("My Wallet"));
    await pumpEventQueue();

    expect(states, isEmpty);
    await sub.cancel();
    await cubit.close();
  });

  test("refresh() updates the groups and re-reads every wallet's addresses", () async {
    final cubit = createCubit();
    await cubit.load();

    await cubit.refresh();
    await pumpEventQueue();

    expect(updateCalls, 1);
    expect(loadCalls, {"btc": 2, "xmr": 2, "ltc": 2});
    expect(cubit.state.currentGroup!.contacts.first.address, "addr_btc_2");
    await cubit.close();
  });

  test("picker mode keeps only contacts valid for the currency", () async {
    final cubit = createCubit(currency: CryptoCurrency.xmr);
    await cubit.load();

    expect(cubit.isPicker, isTrue);
    expect(cubit.state.allContacts.map((c) => c.walletId), ["xmr"]);
    expect(cubit.state.groups.map((g) => g.groupId), ["g1"]);
    await cubit.close();
  });

  test("an older rebuild can't emit after a newer one", () async {
    gates["btc"] = Completer<void>();
    final cubit = createCubit();

    final firstLoad = cubit.load(); // blocked on btc
    await pumpEventQueue();

    // Newer group list without the btc wallet: finishes first.
    subject.add([
      WalletGroup("g1", wallets: [xmr], groupName: "Newer"),
      WalletGroup("g2", wallets: [ltc], groupName: "Other"),
    ]);
    await pumpEventQueue();
    expect(cubit.state.groups.first.name, "Newer");

    final states = <WalletContactsState>[];
    final sub = cubit.stream.listen(states.add);
    gates["btc"]!.complete();
    await firstLoad;
    await pumpEventQueue();

    expect(states, isEmpty);
    expect(cubit.state.groups.first.name, "Newer");
    await sub.cancel();
    await cubit.close();
  });

  test("close() cancels the group subscription; later changes are ignored", () async {
    final cubit = createCubit();
    await cubit.load();
    expect(subject.hasListener, isTrue);

    await cubit.close();

    expect(subject.hasListener, isFalse);
    subject.add(groupsNamed("After close"));
    await pumpEventQueue();
    expect(cubit.state.currentGroup!.name, "My Wallet");
  });

  test("closing during a load doesn't emit afterwards", () async {
    gates["btc"] = Completer<void>();
    final cubit = createCubit();
    final pending = cubit.load();
    await pumpEventQueue();

    await cubit.close();
    gates["btc"]!.complete();

    await expectLater(pending, completes);
  });
}
