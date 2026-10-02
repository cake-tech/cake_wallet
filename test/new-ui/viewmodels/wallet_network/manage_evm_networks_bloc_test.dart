import "dart:async";
import "dart:io";

import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cake_wallet/new-ui/services/evm_network_service.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/manage_evm_networks_bloc.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/evm_network.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart" show ObservableMap;
import "package:mocktail/mocktail.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

class _MockNetworkService extends Mock implements EvmNetworkService {}

class _MockChainListService extends Mock implements ChainListService {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockContactBox extends Mock implements Box<Contact> {}

ChainListEntry _entry(
  int chainId,
  String name,
  List<String> rpcUrls, {
  String symbol = "ETH",
  double? tvl,
}) =>
    ChainListEntry(
      chainId: chainId,
      name: name,
      shortName: name.toLowerCase(),
      symbol: symbol,
      decimals: 18,
      rpcUrls: rpcUrls,
      tvl: tvl,
    );

EvmNetwork _savedRow(
  int chainId,
  String name, {
  String rpcUrl = "https://saved.example",
  String? failoverUrl,
  bool isManual = false,
  bool isEnabled = true,
  int enabledAt = 1,
}) =>
    EvmNetwork(
      chainId: chainId,
      name: name,
      symbol: "SAV",
      decimals: 18,
      tag: "SAV$chainId",
      rpcUrl: rpcUrl,
      failoverUrl: failoverUrl,
      isManual: isManual,
      isEnabled: isEnabled,
      enabledAt: enabledAt,
    );

Future<void> main() async {
  final dataRoot = Directory("./test/data/manage_evm_networks_bloc");

  // OP and Ink are Popular, Ethereum is in the bundled list to check a built-in gets dropped
  final opEntry = _entry(10, "OP Mainnet", ["https://op-1.example", "https://op-2.example"]);
  final inkEntry = _entry(57073, "Ink", ["https://ink-1.example"]);
  final ethereumEntry = _entry(1, "Ethereum Mainnet", ["https://eth.example"]);
  final gnosisEntry = _entry(
    100,
    "Gnosis",
    ["https://gnosis-1.example", "https://gnosis-2.example", "https://gnosis-3.example"],
    symbol: "XDAI",
  );
  final avalancheEntry = _entry(43114, "avalanche C-Chain", ["https://avax.example"]);
  final celoEntry = _entry(42220, "Celo", ["https://celo.example"], symbol: "CELO");
  final fetchedAt = DateTime(2026, 9, 1, 12);
  final cachedAt = DateTime(2026, 8, 20, 9);

  late _MockNetworkService networkService;
  late _MockChainListService chainListService;
  late _MockSettingsStore settingsStore;
  late EvmNetworkService realNetworkService;

  setUpAll(() async {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();

    SharedPreferences.setMockInitialValues({});
    realNetworkService = EvmNetworkService(
      _MockSettingsStore(),
      await SharedPreferences.getInstance(),
      _MockContactBox(),
    );

    registerFallbackValue(_savedRow(1, "fallback"));
    registerFallbackValue(_entry(1, "fallback", const []));
  });

  tearDownAll(() {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await db!.delete(EvmNetwork.tableName);

    networkService = _MockNetworkService();
    chainListService = _MockChainListService();
    settingsStore = _MockSettingsStore();

    when(() => networkService.networkFromEntry(any())).thenAnswer(
      (invocation) => realNetworkService
          .networkFromEntry(invocation.positionalArguments.first as ChainListEntry),
    );
    when(() => chainListService.loadPopularNetworks())
        .thenAnswer((_) async => [opEntry, inkEntry, ethereumEntry]);
    when(() => chainListService.readCache()).thenAnswer((_) async => null);
    when(() => chainListService.fetch()).thenAnswer(
      (_) async => ChainListSnapshot(
        entries: [opEntry, gnosisEntry, avalancheEntry, celoEntry, ethereumEntry],
        fetchedAt: fetchedAt,
      ),
    );
    when(() => settingsStore.evmNetworks).thenReturn(
      ObservableMap.of({
        1: const ChainInfo(
          chainId: 1,
          name: "Ethereum",
          shortCode: "eth",
          currency: CryptoCurrency.eth,
          source: ChainSource.builtin,
        ),
      }),
    );
  });

  ManageEvmNetworksBloc createBloc() =>
      ManageEvmNetworksBloc(networkService, chainListService, settingsStore);

  Future<ManageEvmNetworksState> loaded(ManageEvmNetworksBloc bloc) =>
      bloc.stream.firstWhere((state) => state.chainListStatus is! ChainListFetching);

  group("init", () {
    test("Popular leaves out built-in chains, A-Z leaves out Popular and built-in chains",
        () async {
      final bloc = createBloc();
      final state = await loaded(bloc);

      expect(state.popularNetworks.map((network) => network.chainId), [10, 57073]);
      expect(state.alphabeticalNetworks.map((network) => network.chainId), [43114, 42220, 100]);
      expect(
        state.alphabeticalNetworks.map((network) => network.name),
        ["avalanche C-Chain", "Celo", "Gnosis"],
      );
      expect(state.manualNetworks, isEmpty);
      expect(state.chainListStatus, isA<ChainListLoaded>());

      await bloc.close();
    });

    test("an unsaved row is prefilled from its entry, a saved row replaces it", () async {
      await _savedRow(10, "My OP").save();

      final bloc = createBloc();
      final state = await loaded(bloc);

      final op = state.popularNetworks.first;
      expect(op.name, "My OP");
      expect(op.isEnabled, isTrue);
      final ink = state.popularNetworks.last;
      expect(ink.rpcUrl, "https://ink-1.example");
      expect(ink.isEnabled, isFalse);

      await bloc.close();
    });

    test("manual rows get their own section and leave Popular and A-Z", () async {
      await _savedRow(57073, "My Ink Devnet", isManual: true).save();
      await _savedRow(100, "Gnosis Fork", isManual: true, enabledAt: 2).save();

      final bloc = createBloc();
      final state = await loaded(bloc);

      expect(state.manualNetworks.map((network) => network.name), ["My Ink Devnet", "Gnosis Fork"]);
      expect(state.popularNetworks.map((network) => network.chainId), [10]);
      expect(state.alphabeticalNetworks.map((network) => network.chainId), [43114, 42220]);

      await bloc.close();
    });

    test("an enabled network the feed dropped stays in A-Z", () async {
      await _savedRow(7777777, "Dropped Chain").save();

      final bloc = createBloc();
      final state = await loaded(bloc);

      expect(state.alphabeticalNetworks.map((network) => network.chainId), contains(7777777));

      await bloc.close();
    });

    test("the saved copy shows at once, before the fetch answers", () async {
      final fetch = Completer<ChainListSnapshot>();
      when(() => chainListService.fetch()).thenAnswer((_) => fetch.future);
      when(() => chainListService.readCache()).thenAnswer(
        (_) async => ChainListSnapshot(entries: [celoEntry], fetchedAt: cachedAt),
      );

      final bloc = createBloc();
      final first = await bloc.stream.first;

      expect(first.chainListStatus, isA<ChainListFetching>());
      expect(first.alphabeticalNetworks.map((network) => network.chainId), [42220]);

      final done = loaded(bloc);
      fetch.complete(ChainListSnapshot(entries: [gnosisEntry], fetchedAt: fetchedAt));
      expect((await done).alphabeticalNetworks.map((network) => network.chainId), [100]);

      await bloc.close();
    });

    test("with no saved copy A-Z is loading until the fetch answers", () async {
      final fetch = Completer<ChainListSnapshot>();
      when(() => chainListService.fetch()).thenAnswer((_) => fetch.future);

      final bloc = createBloc();
      final first = await bloc.stream.first;

      expect(first.chainListStatus, isA<ChainListFetching>());
      expect(first.alphabeticalNetworks, isEmpty);
      expect(first.popularNetworks, hasLength(2));

      fetch.complete(ChainListSnapshot(entries: [gnosisEntry], fetchedAt: fetchedAt));
      await bloc.close();
    });
  });

  group("a failed ChainList fetch", () {
    test("falls back to the saved copy and names its date", () async {
      when(() => chainListService.readCache()).thenAnswer(
        (_) async => ChainListSnapshot(entries: [celoEntry, gnosisEntry], fetchedAt: cachedAt),
      );
      when(() => chainListService.fetch()).thenThrow(const SocketException("offline"));

      final bloc = createBloc();
      final state = await loaded(bloc);

      expect(state.alphabeticalNetworks.map((network) => network.chainId), [42220, 100]);
      expect(
        state.chainListStatus,
        isA<ChainListSavedCopy>().having((status) => status.date, "date", cachedAt),
      );

      await bloc.close();
    });

    test("with no saved copy shows the failed state, Popular and manual still load", () async {
      await _savedRow(777001, "Devnet", isManual: true).save();
      when(() => chainListService.fetch()).thenThrow(const SocketException("offline"));

      final bloc = createBloc();
      final state = await loaded(bloc);

      expect(state.chainListStatus, isA<ChainListFetchFailed>());
      expect(state.alphabeticalNetworks, isEmpty);
      expect(state.popularNetworks.map((network) => network.chainId), [10, 57073]);
      expect(state.manualNetworks.map((network) => network.chainId), [777001]);

      await bloc.close();
    });

    test("Try again shows loading, then the fetched list with no saved-copy date", () async {
      when(() => chainListService.fetch()).thenThrow(const SocketException("offline"));
      final bloc = createBloc();
      await loaded(bloc);

      when(() => chainListService.fetch()).thenAnswer(
        (_) async => ChainListSnapshot(entries: [gnosisEntry], fetchedAt: fetchedAt),
      );
      final states = bloc.stream.take(2).toList();
      bloc.add(const ChainListRetryRequested());
      final [retrying, retried] = await states;

      expect(retrying.chainListStatus, isA<ChainListFetching>());
      expect(retrying.alphabeticalNetworks, isEmpty);
      expect(retried.alphabeticalNetworks.map((network) => network.chainId), [100]);
      expect(retried.chainListStatus, isA<ChainListLoaded>());

      await bloc.close();
    });
  });

  group("search", () {
    test("matches the name or symbol in part, and the chain ID exactly", () async {
      final bloc = createBloc();
      await loaded(bloc);

      final byName = bloc.stream.first;
      bloc.add(const ManageEvmNetworksSearchChanged("  CHAIN "));
      final nameState = await byName;
      expect(
        nameState.matchingSearch(nameState.alphabeticalNetworks).map((network) => network.chainId),
        [43114],
      );

      final bySymbol = bloc.stream.first;
      bloc.add(const ManageEvmNetworksSearchChanged("xda"));
      final symbolState = await bySymbol;
      expect(
        symbolState
            .matchingSearch(symbolState.alphabeticalNetworks)
            .map((network) => network.chainId),
        [100],
      );

      final byChainId = bloc.stream.first;
      bloc.add(const ManageEvmNetworksSearchChanged("10"));
      final chainIdState = await byChainId;
      expect(
        chainIdState.matchingSearch(chainIdState.popularNetworks).map((network) => network.chainId),
        [10],
      );
      expect(chainIdState.matchingSearch(chainIdState.alphabeticalNetworks), isEmpty);

      await bloc.close();
    });

    test("no match in any section is reported, an empty query never is", () async {
      final bloc = createBloc();
      await loaded(bloc);

      final searched = bloc.stream.first;
      bloc.add(const ManageEvmNetworksSearchChanged("zzzz"));
      expect((await searched).hasNoMatch, isTrue);

      final cleared = bloc.stream.first;
      bloc.add(const ManageEvmNetworksSearchChanged("   "));
      final clearedState = await cleared;
      expect(clearedState.hasNoMatch, isFalse);
      expect(clearedState.matchingSearch(clearedState.popularNetworks), hasLength(2));

      await bloc.close();
    });
  });

  group("toggle", () {
    test("enabling marks the row as toggling, ignores a second tap, then shows it enabled",
        () async {
      final enable = Completer<EvmNetwork>();
      when(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .thenAnswer((_) => enable.future);
      final bloc = createBloc();
      final state = await loaded(bloc);
      final ink = state.popularNetworks.last;

      final toggling = bloc.stream.first;
      bloc.add(NetworkToggleRequested(ink, shouldEnable: true));
      expect((await toggling).togglingChainIds, {57073});

      bloc.add(NetworkToggleRequested(ink, shouldEnable: true));
      await Future<void>.delayed(Duration.zero);

      final done = bloc.stream.first;
      final enabled = ink.copyWith(isEnabled: true, enabledAt: 5);
      await enabled.save();
      enable.complete(enabled);
      final doneState = await done;

      expect(doneState.togglingChainIds, isEmpty);
      expect(doneState.popularNetworks.last.isEnabled, isTrue);
      verify(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .called(1);

      await bloc.close();
    });

    test("disabling calls the service and clears the toggling set", () async {
      await _savedRow(10, "OP Mainnet").save();
      when(() => networkService.disable(any())).thenAnswer((invocation) async {
        final disabled =
            (invocation.positionalArguments.first as EvmNetwork).copyWith(isEnabled: false);
        await disabled.save();
        return disabled;
      });
      final bloc = createBloc();
      final state = await loaded(bloc);

      final done = bloc.stream.firstWhere((state) => state.togglingChainIds.isEmpty);
      bloc.add(NetworkToggleRequested(state.popularNetworks.first, shouldEnable: false));
      final doneState = await done;

      expect(doneState.popularNetworks.first.isEnabled, isFalse);
      verifyNever(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")));

      await bloc.close();
    });

    test("each refusal is presented once and the toggle is released", () async {
      final bloc = createBloc();
      final state = await loaded(bloc);
      final op = state.popularNetworks.first;
      final presented = <ManageEvmNetworksPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      Future<ManageEvmNetworksState> toggle({required bool shouldEnable}) {
        final released = bloc.stream.firstWhere((state) => state.togglingChainIds.isEmpty);
        bloc.add(NetworkToggleRequested(op, shouldEnable: shouldEnable));
        return released;
      }

      when(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .thenThrow(
        const RpcChainIdMismatchException(
          url: "https://op-1.example",
          answeredChainId: 137,
          expectedChainId: 10,
        ),
      );
      await toggle(shouldEnable: true);

      when(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .thenThrow(const RpcNoAnswerException("https://op-1.example"));
      await toggle(shouldEnable: true);

      when(() => networkService.disable(any()))
          .thenThrow(const NetworkInUseException(walletCount: 3, contactCount: 1));
      await toggle(shouldEnable: false);

      when(() => networkService.disable(any())).thenThrow(StateError("database is locked"));
      final last = await toggle(shouldEnable: false);

      expect(presented, [
        isA<RpcChainIdMismatchRefused>()
            .having((p) => p.networkName, "networkName", "OP Mainnet")
            .having((p) => p.answeredChainId, "answeredChainId", 137)
            .having((p) => p.expectedChainId, "expectedChainId", 10),
        isA<RpcNoAnswerRefused>().having((p) => p.networkName, "networkName", "OP Mainnet"),
        isA<NetworkInUseRefused>()
            .having((p) => p.networkName, "networkName", "OP Mainnet")
            .having((p) => p.walletCount, "walletCount", 3),
        isA<NetworkToggleFailed>()
            .having((p) => p.message, "message", contains("database is locked")),
      ]);
      expect(last.popularNetworks.first.isEnabled, isFalse);

      await subscription.cancel();
      await bloc.close();
    });

    test("a second network's enable waits for the first, both rows show as toggling", () async {
      final firstEnable = Completer<EvmNetwork>();
      final enabledChainIds = <int>[];
      when(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .thenAnswer((invocation) {
        final network = invocation.positionalArguments.first as EvmNetwork;
        enabledChainIds.add(network.chainId);
        return network.chainId == 10 ? firstEnable.future : Future.value(network);
      });
      final bloc = createBloc();
      final state = await loaded(bloc);
      final [op, ink] = state.popularNetworks;

      final bothToggling = bloc.stream.firstWhere((state) => state.togglingChainIds.length == 2);
      bloc.add(NetworkToggleRequested(op, shouldEnable: true));
      bloc.add(NetworkToggleRequested(ink, shouldEnable: true));
      expect((await bothToggling).togglingChainIds, {10, 57073});
      await Future<void>.delayed(Duration.zero);
      expect(enabledChainIds, [10]);

      final released = bloc.stream.firstWhere((state) => state.togglingChainIds.isEmpty);
      firstEnable.complete(op);
      await released;
      expect(enabledChainIds, [10, 57073]);

      await bloc.close();
    });

    test("a refusal that lands after the page closed the bloc is dropped", () async {
      final uncaughtErrors = <Object>[];

      // The bloc and the RPC answer live in this zone, so an error after close lands here
      await runZonedGuarded(
        () async {
          final enable = Completer<EvmNetwork>();
          when(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
              .thenAnswer((_) => enable.future);
          final bloc = createBloc();
          final state = await loaded(bloc);

          final toggling = bloc.stream.first;
          bloc.add(NetworkToggleRequested(state.popularNetworks.first, shouldEnable: true));
          await toggling;
          final closing = bloc.close();
          enable.completeError(const RpcNoAnswerException("https://op-1.example"));
          await closing;
          await Future<void>.delayed(Duration.zero);
        },
        (error, _) => uncaughtErrors.add(error),
      );

      verify(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .called(1);
      expect(uncaughtErrors, isEmpty);
    });
  });

  group("borrowed ticker confirmation", () {
    // Same ticker, only the tvl differs, so the tvl alone decides whether the popup shows
    final cloneEntry = _entry(777100, "Clone Chain", ["https://clone.example"]);
    final lockedValueEntry =
        _entry(777200, "Locked Value Chain", ["https://locked.example"], tvl: 250000000);

    late List<EvmNetwork> enabled;

    setUp(() {
      enabled = [];
      when(() => chainListService.fetch()).thenAnswer(
        (_) async => ChainListSnapshot(
          entries: [opEntry, cloneEntry, lockedValueEntry],
          fetchedAt: fetchedAt,
        ),
      );
      when(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .thenAnswer((invocation) async {
        final network = (invocation.positionalArguments.first as EvmNetwork)
            .copyWith(isEnabled: true, enabledAt: 9);
        await network.save();
        enabled.add(network);
        return network;
      });
    });

    EvmNetwork rowFor(ManageEvmNetworksState state, int chainId) => [
          ...state.popularNetworks,
          ...state.alphabeticalNetworks,
        ].singleWhere((network) => network.chainId == chainId);

    test("an A-Z network on a known ticker with no tvl asks once, then Continue enables it",
        () async {
      final bloc = createBloc();
      final clone = rowFor(await loaded(bloc), 777100);
      final presented = <ManageEvmNetworksPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      final toggling = bloc.stream.first;
      bloc.add(NetworkToggleRequested(clone, shouldEnable: true));
      expect((await toggling).togglingChainIds, {777100});
      bloc.add(NetworkToggleRequested(clone, shouldEnable: true));
      await Future<void>.delayed(Duration.zero);

      expect(presented, [
        isA<BorrowedTickerConfirmationRequested>()
            .having((p) => p.network.chainId, "chainId", 777100),
      ]);
      expect(bloc.state.togglingChainIds, {777100});
      expect(enabled, isEmpty);

      final released = bloc.stream.firstWhere((state) => state.togglingChainIds.isEmpty);
      bloc.add(BorrowedTickerConfirmationAnswered(clone, isConfirmed: true));
      final state = await released;

      expect(enabled.map((network) => network.chainId), [777100]);
      expect(rowFor(state, 777100).isEnabled, isTrue);
      expect(presented, hasLength(1));

      await subscription.cancel();
      await bloc.close();
    });

    test("Cancel leaves the network off and clears the spinner", () async {
      final bloc = createBloc();
      final clone = rowFor(await loaded(bloc), 777100);

      final toggling = bloc.stream.first;
      bloc.add(NetworkToggleRequested(clone, shouldEnable: true));
      await toggling;

      final cancelled = bloc.stream.first;
      bloc.add(BorrowedTickerConfirmationAnswered(clone, isConfirmed: false));
      final state = await cancelled;

      expect(state.togglingChainIds, isEmpty);
      expect(rowFor(state, 777100).isEnabled, isFalse);
      expect(enabled, isEmpty);

      await bloc.close();
    });

    test("a Popular network on ETH, or an A-Z one on ETH with tvl, enables without asking",
        () async {
      final bloc = createBloc();
      final state = await loaded(bloc);
      final presented = <ManageEvmNetworksPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      for (final chainId in [10, 777200]) {
        final released = bloc.stream.firstWhere((state) => state.togglingChainIds.isEmpty);
        bloc.add(NetworkToggleRequested(rowFor(state, chainId), shouldEnable: true));
        await released;
      }

      expect(presented, isEmpty);
      expect(enabled.map((network) => network.chainId), [10, 777200]);

      await subscription.cancel();
      await bloc.close();
    });
  });

  group("RPC candidates on enable", () {
    Future<List<String>> candidatesFor(
      EvmNetwork Function(ManageEvmNetworksState state) pick,
    ) async {
      final enabledWith = <List<String>>[];
      when(() => networkService.enable(any(), rpcCandidates: any(named: "rpcCandidates")))
          .thenAnswer((invocation) async {
        enabledWith.add(invocation.namedArguments[#rpcCandidates] as List<String>);
        return invocation.positionalArguments.first as EvmNetwork;
      });
      final bloc = createBloc();
      final state = await loaded(bloc);

      final released = bloc.stream.firstWhere((state) => state.togglingChainIds.isEmpty);
      bloc.add(NetworkToggleRequested(pick(state), shouldEnable: true));
      await released;
      await bloc.close();

      return enabledWith.single;
    }

    test("an A-Z network on its prefilled RPCs walks the feed's RPC list", () async {
      final candidates = await candidatesFor(
        (state) => state.alphabeticalNetworks.singleWhere((network) => network.chainId == 100),
      );

      expect(candidates, gnosisEntry.rpcUrls);
    });

    test("an A-Z network the user moved to another RPC keeps the strict check", () async {
      await _savedRow(100, "Gnosis", rpcUrl: "https://my-own.example", isEnabled: false).save();

      final candidates = await candidatesFor(
        (state) => state.alphabeticalNetworks.singleWhere((network) => network.chainId == 100),
      );

      expect(candidates, isEmpty);
    });

    test("an A-Z network re-enabled on later listed RPCs walks the list, stored pair first",
        () async {
      await _savedRow(
        100,
        "Gnosis",
        rpcUrl: "https://gnosis-2.example",
        failoverUrl: "https://gnosis-3.example",
        isEnabled: false,
      ).save();

      final candidates = await candidatesFor(
        (state) => state.alphabeticalNetworks.singleWhere((network) => network.chainId == 100),
      );

      expect(candidates, [
        "https://gnosis-2.example",
        "https://gnosis-3.example",
        "https://gnosis-1.example",
      ]);
    });

    test("an A-Z network with a failover the user typed keeps the strict check", () async {
      await _savedRow(
        100,
        "Gnosis",
        rpcUrl: "https://gnosis-1.example",
        failoverUrl: "https://my-own.example",
        isEnabled: false,
      ).save();

      final candidates = await candidatesFor(
        (state) => state.alphabeticalNetworks.singleWhere((network) => network.chainId == 100),
      );

      expect(candidates, isEmpty);
    });

    test("a Popular network on its bundled RPCs walks the bundled RPC list", () async {
      final candidates = await candidatesFor((state) => state.popularNetworks.first);

      expect(candidates, opEntry.rpcUrls);
    });

    test("a Popular network re-enabled on its second RPC alone walks the list from it", () async {
      await _savedRow(10, "OP Mainnet", rpcUrl: "https://op-2.example", isEnabled: false).save();

      final candidates = await candidatesFor((state) => state.popularNetworks.first);

      expect(candidates, ["https://op-2.example", "https://op-1.example"]);
    });

    test("a Popular network the user moved to another RPC keeps the strict check", () async {
      await _savedRow(10, "OP Mainnet", rpcUrl: "https://my-op.example", isEnabled: false).save();

      final candidates = await candidatesFor((state) => state.popularNetworks.first);

      expect(candidates, isEmpty);
    });

    test("a manual network keeps the strict check", () async {
      await _savedRow(
        42220,
        "Celo Devnet",
        rpcUrl: "https://celo.example",
        isManual: true,
        isEnabled: false,
      ).save();

      final candidates = await candidatesFor((state) => state.manualNetworks.single);

      expect(candidates, isEmpty);
    });
  });

  test("NetworksChanged rereads the saved rows after the details page returns", () async {
    final bloc = createBloc();
    await loaded(bloc);
    await _savedRow(777001, "Devnet", isManual: true).save();

    final changed = bloc.stream.first;
    bloc.add(const NetworksChanged());
    final state = await changed;

    expect(state.manualNetworks.map((network) => network.chainId), [777001]);
    expect(state.alphabeticalNetworks, isNotEmpty);

    await bloc.close();
  });
}
