import "dart:async";
import "dart:io";

import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cake_wallet/new-ui/services/evm_network_service.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/network_details_bloc.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/node.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableMap;
import "package:mocktail/mocktail.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
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

Future<void> main() async {
  final dataRoot = Directory("./test/data/network_details_bloc");

  const inkEntry = ChainListEntry(
    chainId: 57073,
    name: "Ink",
    shortName: "ink",
    symbol: "ETH",
    decimals: 18,
    rpcUrls: ["https://ink-default.example", "https://ink-default-failover.example"],
    explorerUrl: "https://explorer.inkonchain.com",
  );
  const cronosEntry = ChainListEntry(
    chainId: 25,
    name: "Cronos",
    shortName: "cro",
    symbol: "CRO",
    decimals: 18,
    rpcUrls: ["https://cronos-default.example"],
  );
  const celoCachedEntry = ChainListEntry(
    chainId: 42220,
    name: "Celo",
    shortName: "celo",
    symbol: "CELO",
    decimals: 18,
    rpcUrls: ["https://celo-default.example"],
  );

  // A Popular network the user enabled and edited, still on ChainList
  final ink = EvmNetwork(
    chainId: 57073,
    name: "My Ink",
    symbol: "ETH",
    decimals: 18,
    tag: "INK",
    rpcUrl: "https://ink-stored.example",
    failoverUrl: "https://ink-stored-failover.example",
    explorerUrl: "https://my-explorer.example",
    iconUrl: "assets/new-ui/network_icons/ink.svg",
    isEnabled: true,
    enabledAt: 11,
  );
  final devnet = EvmNetwork(
    chainId: 777001,
    name: "Devnet",
    symbol: "DEV",
    decimals: 6,
    tag: "DEVNET",
    rpcUrl: "https://devnet-rpc.example",
    isManual: true,
    isEnabled: true,
    enabledAt: 22,
  );
  final otherSaved = EvmNetwork(
    chainId: 777002,
    name: "Other Chain",
    symbol: "OTH",
    decimals: 18,
    tag: "OTH",
    rpcUrl: "https://other-rpc.example",
    isManual: true,
  );
  final currentNode = Node(
    uri: "ink-current-node.example",
    path: "/rpc",
    useSSL: true,
    type: WalletType.evm,
    chainId: 57073,
  );

  late _MockNetworkService networkService;
  late _MockChainListService chainListService;
  late _MockSettingsStore settingsStore;

  setUpAll(() async {
    S.current = const S();

    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();

    registerFallbackValue(devnet);
  });

  tearDownAll(() {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await db!.delete(EvmNetwork.tableName);
    await ink.save();
    await devnet.save();
    await otherSaved.save();

    networkService = _MockNetworkService();
    chainListService = _MockChainListService();
    settingsStore = _MockSettingsStore();

    when(() => chainListService.loadPopularNetworks())
        .thenAnswer((_) async => [inkEntry, cronosEntry]);
    when(() => chainListService.readCache()).thenAnswer(
      (_) async => ChainListSnapshot(entries: [celoCachedEntry], fetchedAt: DateTime(2026, 9)),
    );
    when(() => networkService.walletCount(any())).thenAnswer((_) async => 0);
    when(() => networkService.contactCount(any())).thenReturn(0);
    when(() => networkService.save(any(), previous: any(named: "previous"))).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as EvmNetwork,
    );
    when(() => settingsStore.evmNetworks).thenReturn(
      ObservableMap.of({
        56: const ChainInfo(
          chainId: 56,
          name: "BNB Smart Chain",
          shortCode: "bsc",
          currency: CryptoCurrency.bnb,
          source: ChainSource.builtin,
        ),
      }),
    );
    when(() => settingsStore.evmChainNodes).thenReturn(ObservableMap<int, Node>());
  });

  NetworkDetailsBloc createBloc(EvmNetwork? network) =>
      NetworkDetailsBloc(network, networkService, chainListService, settingsStore);

  Future<NetworkDetailsState> opened(NetworkDetailsBloc bloc) =>
      bloc.stream.firstWhere((state) => state.hasUsageCounts);

  Future<NetworkDetailsState> change(NetworkDetailsBloc bloc, NetworkField field, String value) {
    final changed = bloc.stream.first;
    bloc.add(NetworkFieldChanged(field, value));
    return changed;
  }

  Future<NetworkDetailsState> save(NetworkDetailsBloc bloc) {
    final settled = bloc.stream.firstWhere((state) => !state.isSaving);
    bloc.add(const NetworkSaveRequested());
    return settled;
  }

  // A manual add with every field valid, so each validation test breaks exactly one field
  Future<NetworkDetailsBloc> filledManualAdd() async {
    final bloc = createBloc(null);
    await opened(bloc);
    await change(bloc, NetworkField.name, "Fresh Chain");
    await change(bloc, NetworkField.rpcUrl, "https://fresh-rpc.example");
    await change(bloc, NetworkField.chainId, "888001");
    await change(bloc, NetworkField.symbol, "FRSH");
    return bloc;
  }

  group("mode and open", () {
    test("no network opens manual add with zero counts and no reset", () async {
      final bloc = createBloc(null);
      final state = await opened(bloc);

      expect(state.mode, NetworkDetailsMode.manualAdd);
      expect(state.walletCount, 0);
      expect(state.contactCount, 0);
      expect(bloc.canResetToDefault, isFalse);
      expect(state.values.values.every((value) => value.isEmpty), isTrue);
      verifyNever(() => networkService.walletCount(any()));

      await bloc.close();
    });

    test("a manual row opens manual edit with its values and counts", () async {
      when(() => networkService.walletCount(devnet.chainId)).thenAnswer((_) async => 0);
      when(() => networkService.contactCount(devnet.chainId)).thenReturn(2);

      final bloc = createBloc(devnet);
      final state = await opened(bloc);

      expect(state.mode, NetworkDetailsMode.manualEdit);
      expect(state.value(NetworkField.chainId), "777001");
      expect(state.value(NetworkField.rpcUrl), "https://devnet-rpc.example");
      expect(state.contactCount, 2);
      expect(bloc.canResetToDefault, isFalse);

      await bloc.close();
    });

    test("a ChainList row opens ChainList mode, resettable when its entry is known", () async {
      final bloc = createBloc(ink);
      final state = await opened(bloc);

      expect(state.mode, NetworkDetailsMode.chainList);
      expect(bloc.canResetToDefault, isTrue);
      expect(state.isFailoverRevealed, isTrue);
      expect(state.isReadOnly(NetworkField.chainId), isTrue);

      await bloc.close();
    });

    test("a ChainList row whose entry is neither Popular nor cached cannot reset", () async {
      final unlisted = EvmNetwork(
        chainId: 999999,
        name: "Unlisted",
        symbol: "UNL",
        decimals: 18,
        tag: "UNL",
        rpcUrl: "https://unlisted.example",
      );

      final bloc = createBloc(unlisted);
      await opened(bloc);

      expect(bloc.canResetToDefault, isFalse);

      await bloc.close();
    });

    test("with wallets the RPC field shows the wallets' current node and fills the field",
        () async {
      when(() => networkService.walletCount(ink.chainId)).thenAnswer((_) async => 1);
      when(() => settingsStore.evmChainNodes).thenReturn(ObservableMap.of({57073: currentNode}));
      final bloc = createBloc(ink);
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      final state = await opened(bloc);
      await Future<void>.delayed(Duration.zero);

      expect(state.value(NetworkField.rpcUrl), "https://ink-current-node.example/rpc");
      expect(presented, [
        isA<NetworkDetailsFieldsFilled>().having(
          (p) => p.values[NetworkField.rpcUrl],
          "rpcUrl",
          "https://ink-current-node.example/rpc",
        ),
      ]);
      expect(state.isReadOnly(NetworkField.rpcUrl), isTrue);
      expect(state.isReadOnly(NetworkField.failoverUrl), isTrue);
      expect(state.isReadOnly(NetworkField.symbol), isTrue);
      expect(state.isReadOnly(NetworkField.name), isFalse);

      await subscription.cancel();
      await bloc.close();
    });

    test("without wallets the stored RPC shows and nothing is filled", () async {
      when(() => settingsStore.evmChainNodes).thenReturn(ObservableMap.of({57073: currentNode}));
      final bloc = createBloc(ink);
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      final state = await opened(bloc);
      await Future<void>.delayed(Duration.zero);

      expect(state.value(NetworkField.rpcUrl), "https://ink-stored.example");
      expect(presented, isEmpty);

      await subscription.cancel();
      await bloc.close();
    });

    test("contacts lock the chain ID of a manual network, not its RPC", () async {
      when(() => networkService.contactCount(devnet.chainId)).thenReturn(1);

      final bloc = createBloc(devnet);
      final state = await opened(bloc);

      expect(state.isReadOnly(NetworkField.chainId), isTrue);
      expect(state.isReadOnly(NetworkField.rpcUrl), isFalse);
      expect(state.canDelete, isFalse);

      await bloc.close();
    });
  });

  group("validation", () {
    test("a ChainList symbol the form would refuse is kept when only the name changes", () async {
      final milkomeda = EvmNetwork(
        chainId: 2001,
        name: "Milkomeda C1",
        symbol: "mADA",
        decimals: 18,
        tag: "MILKADA",
        rpcUrl: "https://milkomeda.example",
        isEnabled: true,
        enabledAt: 12,
      );
      final bloc = createBloc(milkomeda);
      await opened(bloc);
      await change(bloc, NetworkField.name, "Milkomeda");

      final state = await save(bloc);

      expect(state.errors, isEmpty);
      final saved = verify(
        () => networkService.save(captureAny(), previous: any(named: "previous")),
      ).captured.single as EvmNetwork;
      expect(saved.symbol, "mADA");

      await bloc.close();
    });

    test("a valid manual add passes and saves", () async {
      final bloc = await filledManualAdd();

      final state = await save(bloc);

      expect(state.errors, isEmpty);
      verify(() => networkService.save(any(), previous: null)).called(1);

      await bloc.close();
    });

    test("an empty name and one past 32 characters are refused, 32 is allowed", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.name, "   ");
      expect((await save(bloc)).errors[NetworkField.name], S.current.field_required);

      await change(bloc, NetworkField.name, "x" * 33);
      expect((await save(bloc)).errors[NetworkField.name], S.current.network_name_too_long);

      await change(bloc, NetworkField.name, "x" * 32);
      expect((await save(bloc)).errors[NetworkField.name], isNull);

      await bloc.close();
    });

    test("the name cap counts an emoji as one character, like the feed's cut", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.name, "${"x" * 31}\u{1F680}");
      expect((await save(bloc)).errors[NetworkField.name], isNull);

      await change(bloc, NetworkField.name, "${"x" * 32}\u{1F680}");
      expect((await save(bloc)).errors[NetworkField.name], S.current.network_name_too_long);

      await bloc.close();
    });

    test("a name used by a built-in or another added network is refused, ignoring case", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.name, "ethereum");
      expect(
        (await save(bloc)).errors[NetworkField.name],
        S.current.network_name_exists("ethereum"),
      );

      await change(bloc, NetworkField.name, "bnb smart chain");
      expect(
        (await save(bloc)).errors[NetworkField.name],
        S.current.network_name_exists("bnb smart chain"),
      );

      await change(bloc, NetworkField.name, "OTHER CHAIN");
      expect(
        (await save(bloc)).errors[NetworkField.name],
        S.current.network_name_exists("OTHER CHAIN"),
      );

      await bloc.close();
    });

    test("editing keeps the network's own name without a clash", () async {
      final bloc = createBloc(devnet);
      await opened(bloc);

      expect((await save(bloc)).errors, isEmpty);

      await bloc.close();
    });

    test("the RPC is required and must be https with a host", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.rpcUrl, "");
      expect((await save(bloc)).errors[NetworkField.rpcUrl], S.current.field_required);

      await change(bloc, NetworkField.rpcUrl, "http://fresh-rpc.example");
      expect((await save(bloc)).errors[NetworkField.rpcUrl], S.current.url_must_be_https);

      await change(bloc, NetworkField.rpcUrl, "https://");
      expect((await save(bloc)).errors[NetworkField.rpcUrl], S.current.url_must_be_https);

      await change(bloc, NetworkField.rpcUrl, "wss://fresh-rpc.example");
      expect((await save(bloc)).errors[NetworkField.rpcUrl], S.current.url_must_be_https);

      verifyNever(() => networkService.save(any(), previous: any(named: "previous")));
      await bloc.close();
    });

    test("the failover must be https and differ from the RPC", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.failoverUrl, "http://failover.example");
      expect((await save(bloc)).errors[NetworkField.failoverUrl], S.current.url_must_be_https);

      await change(bloc, NetworkField.failoverUrl, " https://fresh-rpc.example ");
      expect((await save(bloc)).errors[NetworkField.failoverUrl], S.current.failover_must_differ);

      await bloc.close();
    });

    test("the chain ID must be a positive decimal or 0x hex number", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.chainId, "");
      expect((await save(bloc)).errors[NetworkField.chainId], S.current.field_required);

      for (final input in ["abc", "0", "-5", "1.5", "0x", "0xzz", "0x0"]) {
        await change(bloc, NetworkField.chainId, input);
        expect(
          (await save(bloc)).errors[NetworkField.chainId],
          S.current.chain_id_whole_number,
          reason: input,
        );
      }

      await bloc.close();
    });

    test("a hex chain ID is saved as its number", () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.chainId, "0XD8E21");

      await save(bloc);

      final saved = verify(
        () => networkService.save(captureAny(), previous: any(named: "previous")),
      ).captured.single as EvmNetwork;
      expect(saved.chainId, 888353);

      await bloc.close();
    });

    test("a built-in chain ID, or one another added network uses, is refused", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.chainId, "56");
      expect(
        (await save(bloc)).errors[NetworkField.chainId],
        S.current.chain_id_used_by_builtin("56", "BNB Smart Chain"),
      );

      await change(bloc, NetworkField.chainId, "0xbdb2a");
      expect(
        (await save(bloc)).errors[NetworkField.chainId],
        S.current.chain_id_used_by_network("777002", "Other Chain"),
      );

      await bloc.close();
    });

    test("adding a chain ChainList lists is refused, Popular or saved copy", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.chainId, "25");
      expect(
        (await save(bloc)).errors[NetworkField.chainId],
        S.current.chain_id_listed_on_chainlist("25", "Cronos"),
      );

      await change(bloc, NetworkField.chainId, "42220");
      expect(
        (await save(bloc)).errors[NetworkField.chainId],
        S.current.chain_id_listed_on_chainlist("42220", "Celo"),
      );

      await bloc.close();
    });

    test("editing a manual network onto a chain ChainList lists is allowed", () async {
      final bloc = createBloc(devnet);
      await opened(bloc);

      await change(bloc, NetworkField.chainId, "42220");
      final state = await save(bloc);

      expect(state.errors, isEmpty);

      await bloc.close();
    });

    test("the symbol is upper-cased as typed and must be 1 to 10 letters or digits", () async {
      final bloc = await filledManualAdd();

      expect((await change(bloc, NetworkField.symbol, "frsh")).value(NetworkField.symbol), "FRSH");

      await change(bloc, NetworkField.symbol, " ");
      expect((await save(bloc)).errors[NetworkField.symbol], S.current.field_required);

      for (final input in ["ABCDEFGHIJK", "E-TH", "ÉTH"]) {
        await change(bloc, NetworkField.symbol, input);
        expect(
          (await save(bloc)).errors[NetworkField.symbol],
          S.current.symbol_format,
          reason: input,
        );
      }

      await change(bloc, NetworkField.symbol, "ABCDEFGHIJ");
      expect((await save(bloc)).errors[NetworkField.symbol], isNull);

      await bloc.close();
    });

    test("the explorer and a manual icon must be https", () async {
      final bloc = await filledManualAdd();

      await change(bloc, NetworkField.explorerUrl, "http://explorer.example");
      await change(bloc, NetworkField.iconUrl, "assets/new-ui/network_icons/ink.svg");
      final state = await save(bloc);

      expect(state.errors[NetworkField.explorerUrl], S.current.url_must_be_https);
      expect(state.errors[NetworkField.iconUrl], S.current.url_must_be_https);

      await bloc.close();
    });

    test("changing a field clears only that field's error", () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.rpcUrl, "http://fresh-rpc.example");
      await change(bloc, NetworkField.symbol, "");
      await save(bloc);

      final state = await change(bloc, NetworkField.rpcUrl, "https://fresh-rpc.example");

      expect(state.errors.keys, [NetworkField.symbol]);

      await bloc.close();
    });

    test("with wallets the locked RPC and symbol are saved as they were", () async {
      when(() => networkService.walletCount(ink.chainId)).thenAnswer((_) async => 2);
      final bloc = createBloc(ink);
      await opened(bloc);
      await change(bloc, NetworkField.rpcUrl, "http://locked.example");
      await change(bloc, NetworkField.symbol, "lower-case");

      final state = await save(bloc);

      expect(state.errors, isEmpty);
      final saved = verify(
        () => networkService.save(captureAny(), previous: any(named: "previous")),
      ).captured.single as EvmNetwork;
      expect(saved.symbol, ink.symbol);
      expect(saved.rpcUrl, ink.rpcUrl);

      await bloc.close();
    });
  });

  group("save", () {
    test("a manual add saves the trimmed form as a manual network with a tag from its name",
        () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.name, "  Fresh Chain  ");
      await change(bloc, NetworkField.explorerUrl, " https://fresh-explorer.example ");
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      await save(bloc);
      await Future<void>.delayed(Duration.zero);

      final saved = verify(
        () => networkService.save(captureAny(), previous: null),
      ).captured.single as EvmNetwork;
      expect(saved.chainId, 888001);
      expect(saved.name, "Fresh Chain");
      expect(saved.symbol, "FRSH");
      expect(saved.decimals, 18);
      expect(saved.tag, "FRESHCHAIN");
      expect(saved.rpcUrl, "https://fresh-rpc.example");
      expect(saved.failoverUrl, isNull);
      expect(saved.explorerUrl, "https://fresh-explorer.example");
      expect(saved.iconUrl, isNull);
      expect(saved.isManual, isTrue);
      expect(saved.isEnabled, isTrue);
      expect(presented, [isA<NetworkDetailsSaved>()]);

      await subscription.cancel();
      await bloc.close();
    });

    test("a ChainList edit keeps the row's tag, icon, decimals and enabled state", () async {
      // Ink turned off with 8 decimals, values the ?? fallbacks would never give
      final disabledInk = EvmNetwork(
        chainId: ink.chainId,
        name: ink.name,
        symbol: ink.symbol,
        decimals: 8,
        tag: ink.tag,
        rpcUrl: ink.rpcUrl,
        failoverUrl: ink.failoverUrl,
        explorerUrl: ink.explorerUrl,
        iconUrl: ink.iconUrl,
        isEnabled: false,
        enabledAt: ink.enabledAt,
      );
      final bloc = createBloc(disabledInk);
      await opened(bloc);
      await change(bloc, NetworkField.name, "Ink Renamed");

      await save(bloc);

      final captured = verify(
        () => networkService.save(captureAny(), previous: captureAny(named: "previous")),
      ).captured;
      final saved = captured.first as EvmNetwork;
      expect(captured.last, same(disabledInk));
      expect(saved.name, "Ink Renamed");
      expect(saved.tag, "INK");
      expect(saved.iconUrl, "assets/new-ui/network_icons/ink.svg");
      expect(saved.isManual, isFalse);
      expect(saved.enabledAt, 11);
      expect(saved.decimals, 8);
      expect(saved.isEnabled, isFalse);

      await bloc.close();
    });

    test("with wallets the stored RPCs are saved, not the current node shown", () async {
      when(() => networkService.walletCount(ink.chainId)).thenAnswer((_) async => 1);
      when(() => settingsStore.evmChainNodes).thenReturn(ObservableMap.of({57073: currentNode}));
      final bloc = createBloc(ink);
      await opened(bloc);

      await save(bloc);

      final saved = verify(
        () => networkService.save(captureAny(), previous: any(named: "previous")),
      ).captured.single as EvmNetwork;
      expect(saved.rpcUrl, "https://ink-stored.example");
      expect(saved.failoverUrl, "https://ink-stored-failover.example");

      await bloc.close();
    });

    test("a manual edit keeps the network's own decimals", () async {
      final bloc = createBloc(devnet);
      await opened(bloc);

      await save(bloc);

      final saved = verify(
        () => networkService.save(captureAny(), previous: any(named: "previous")),
      ).captured.single as EvmNetwork;
      expect(saved.decimals, 6);

      await bloc.close();
    });

    test("an RPC on another chain puts the mismatch on the field holding that URL", () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.failoverUrl, "https://fresh-failover.example");

      when(() => networkService.save(any(), previous: any(named: "previous"))).thenThrow(
        const RpcChainIdMismatchException(
          url: "https://fresh-failover.example",
          answeredChainId: 137,
          expectedChainId: 888001,
        ),
      );
      final failoverState = await save(bloc);
      expect(failoverState.errors, {
        NetworkField.failoverUrl: S.current.rpc_field_chain_id_mismatch("137", "888001"),
      });

      when(() => networkService.save(any(), previous: any(named: "previous"))).thenThrow(
        const RpcChainIdMismatchException(
          url: "https://fresh-rpc.example",
          answeredChainId: 10,
          expectedChainId: 888001,
        ),
      );
      final rpcState = await save(bloc);
      expect(rpcState.errors, {
        NetworkField.rpcUrl: S.current.rpc_field_chain_id_mismatch("10", "888001"),
      });

      await bloc.close();
    });

    test("an RPC that does not answer gets the no-answer message on its field", () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.failoverUrl, "https://fresh-failover.example");
      when(() => networkService.save(any(), previous: any(named: "previous")))
          .thenThrow(const RpcNoAnswerException("https://fresh-rpc.example"));

      final state = await save(bloc);

      expect(state.errors, {NetworkField.rpcUrl: S.current.rpc_field_no_answer});
      expect(state.isSaving, isFalse);

      await bloc.close();
    });

    test("any other failure is presented and nothing is marked saved", () async {
      final bloc = await filledManualAdd();
      when(() => networkService.save(any(), previous: any(named: "previous")))
          .thenThrow(StateError("disk full"));
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      final state = await save(bloc);
      await Future<void>.delayed(Duration.zero);

      expect(state.isSaving, isFalse);
      expect(state.errors, isEmpty);
      expect(presented, [
        isA<NetworkDetailsFailed>().having((p) => p.message, "message", contains("disk full")),
      ]);

      await subscription.cancel();
      await bloc.close();
    });

    test("saving shows progress and a second tap while saving is dropped", () async {
      final bloc = await filledManualAdd();
      final saving = Completer<EvmNetwork>();
      when(() => networkService.save(any(), previous: any(named: "previous")))
          .thenAnswer((_) => saving.future);

      final started = bloc.stream.first;
      bloc.add(const NetworkSaveRequested());
      expect((await started).isSaving, isTrue);

      bloc.add(const NetworkSaveRequested());
      await Future<void>.delayed(Duration.zero);
      final settled = bloc.stream.firstWhere((state) => !state.isSaving);
      saving.complete(devnet);
      await settled;

      verify(() => networkService.save(any(), previous: any(named: "previous"))).called(1);
      await bloc.close();
    });
  });

  group("borrowed ticker confirmation", () {
    final ethDevnet = EvmNetwork(
      chainId: 777003,
      name: "Eth Devnet",
      symbol: "ETH",
      decimals: 18,
      tag: "ETHDEVNET",
      rpcUrl: "https://eth-devnet-rpc.example",
      isManual: true,
      isEnabled: true,
      enabledAt: 33,
    );

    late List<NetworkDetailsPresentation> presented;
    late StreamSubscription<NetworkDetailsPresentation> subscription;

    Future<void> requestSave(NetworkDetailsBloc bloc) async {
      presented = [];
      subscription = bloc.presentation.listen(presented.add);
      bloc.add(const NetworkSaveRequested());
      await Future<void>.delayed(Duration.zero);
    }

    tearDown(() => subscription.cancel());

    test("a manual add on BTC asks first and saves only after Continue", () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.symbol, "BTC");

      await requestSave(bloc);

      expect(presented, [
        isA<BorrowedTickerConfirmationRequested>()
            .having((p) => p.networkName, "networkName", "Fresh Chain")
            .having((p) => p.symbol, "symbol", "BTC"),
      ]);
      expect(bloc.state.isSaving, isTrue);
      verifyNever(() => networkService.save(any(), previous: any(named: "previous")));

      final settled = bloc.stream.firstWhere((state) => !state.isSaving);
      bloc.add(const BorrowedTickerConfirmationAnswered(isConfirmed: true));
      await settled;
      await Future<void>.delayed(Duration.zero);

      final saved = verify(() => networkService.save(captureAny(), previous: null)).captured.single
          as EvmNetwork;
      expect(saved.symbol, "BTC");
      expect(presented.last, isA<NetworkDetailsSaved>());

      await bloc.close();
    });

    test("Cancel stops saving and saves nothing", () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.symbol, "BTC");
      await requestSave(bloc);

      final cancelled = bloc.stream.first;
      bloc.add(const BorrowedTickerConfirmationAnswered(isConfirmed: false));
      final state = await cancelled;
      await Future<void>.delayed(Duration.zero);

      expect(state.isSaving, isFalse);
      expect(presented, [isA<BorrowedTickerConfirmationRequested>()]);
      verifyNever(() => networkService.save(any(), previous: any(named: "previous")));

      await bloc.close();
    });

    test("a manual add on a ticker the app does not know saves without asking", () async {
      final bloc = await filledManualAdd();
      await change(bloc, NetworkField.symbol, "SEP");

      await requestSave(bloc);

      expect(presented, [isA<NetworkDetailsSaved>()]);
      verify(() => networkService.save(any(), previous: null)).called(1);

      await bloc.close();
    });

    test("a manual edit that keeps its known ticker saves without asking again", () async {
      final bloc = createBloc(ethDevnet);
      await opened(bloc);
      await change(bloc, NetworkField.name, "Eth Devnet Renamed");

      await requestSave(bloc);

      expect(presented, [isA<NetworkDetailsSaved>()]);
      verify(() => networkService.save(any(), previous: ethDevnet)).called(1);

      await bloc.close();
    });

    test("a manual edit onto a known ticker asks first", () async {
      final bloc = createBloc(devnet);
      await opened(bloc);
      await change(bloc, NetworkField.symbol, "BNB");

      await requestSave(bloc);

      expect(presented, [
        isA<BorrowedTickerConfirmationRequested>()
            .having((p) => p.networkName, "networkName", "Devnet")
            .having((p) => p.symbol, "symbol", "BNB"),
      ]);
      verifyNever(() => networkService.save(any(), previous: any(named: "previous")));

      await bloc.close();
    });
  });

  group("save before and against usage", () {
    test("a save before the counts load is ignored", () async {
      final walletCount = Completer<int>();
      when(() => networkService.walletCount(any())).thenAnswer((_) => walletCount.future);
      final bloc = createBloc(devnet);
      final states = <NetworkDetailsState>[];
      final subscription = bloc.stream.listen(states.add);
      await Future<void>.delayed(Duration.zero);

      bloc.add(const NetworkSaveRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.hasUsageCounts, isFalse);
      expect(states.where((state) => state.isSaving), isEmpty);
      verifyNever(() => networkService.save(any(), previous: any(named: "previous")));

      walletCount.complete(0);
      await subscription.cancel();
      await bloc.close();
    });

    test("a chain ID change the service refuses puts the saved one back and locks it", () async {
      when(() => networkService.save(any(), previous: any(named: "previous")))
          .thenThrow(const NetworkInUseException(walletCount: 0, contactCount: 2));
      final bloc = createBloc(devnet);
      await opened(bloc);
      await change(bloc, NetworkField.chainId, "888002");
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      final state = await save(bloc);
      await Future<void>.delayed(Duration.zero);

      expect(state.value(NetworkField.chainId), "777001");
      expect(state.contactCount, 2);
      expect(state.isReadOnly(NetworkField.chainId), isTrue);
      expect(presented, [
        isA<NetworkDetailsFieldsFilled>()
            .having((p) => p.values[NetworkField.chainId], "chainId", "777001"),
      ]);

      await subscription.cancel();
      await bloc.close();
    });
  });

  group("Reset to Default", () {
    test("copies name, explorer and both RPCs from the entry and fills the fields", () async {
      final bloc = createBloc(ink);
      await opened(bloc);
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      final reset = bloc.stream.first;
      bloc.add(const ResetToDefaultRequested());
      final state = await reset;
      await Future<void>.delayed(Duration.zero);

      expect(state.value(NetworkField.name), "Ink");
      expect(state.value(NetworkField.explorerUrl), "https://explorer.inkonchain.com");
      expect(state.value(NetworkField.rpcUrl), "https://ink-default.example");
      expect(state.value(NetworkField.failoverUrl), "https://ink-default-failover.example");
      expect(presented, [
        isA<NetworkDetailsFieldsFilled>()
            .having((p) => p.values[NetworkField.name], "name", "Ink")
            .having((p) => p.values[NetworkField.rpcUrl], "rpcUrl", "https://ink-default.example"),
      ]);
      verifyNever(() => networkService.save(any(), previous: any(named: "previous")));

      await subscription.cancel();
      await bloc.close();
    });

    test("an entry with one RPC clears the failover", () async {
      final celo = EvmNetwork(
        chainId: 42220,
        name: "Celo Edited",
        symbol: "CELO",
        decimals: 18,
        tag: "CELO",
        rpcUrl: "https://celo-edited.example",
        failoverUrl: "https://celo-edited-failover.example",
      );
      final bloc = createBloc(celo);
      await opened(bloc);

      final reset = bloc.stream.first;
      bloc.add(const ResetToDefaultRequested());
      final state = await reset;

      expect(state.value(NetworkField.rpcUrl), "https://celo-default.example");
      expect(state.value(NetworkField.failoverUrl), "");
      expect(state.value(NetworkField.explorerUrl), "");

      await bloc.close();
    });

    test("with wallets the RPCs are left as they are", () async {
      when(() => networkService.walletCount(ink.chainId)).thenAnswer((_) async => 1);
      when(() => settingsStore.evmChainNodes).thenReturn(ObservableMap.of({57073: currentNode}));
      final bloc = createBloc(ink);
      await opened(bloc);

      final reset = bloc.stream.first;
      bloc.add(const ResetToDefaultRequested());
      final state = await reset;

      expect(state.value(NetworkField.name), "Ink");
      expect(state.value(NetworkField.rpcUrl), "https://ink-current-node.example/rpc");
      expect(state.value(NetworkField.failoverUrl), "https://ink-stored-failover.example");

      await bloc.close();
    });

    test("clears the errors of the fields it filled", () async {
      final bloc = createBloc(ink);
      await opened(bloc);
      await change(bloc, NetworkField.name, "");
      await change(bloc, NetworkField.rpcUrl, "http://bad.example");
      await change(bloc, NetworkField.symbol, "");
      await save(bloc);

      final reset = bloc.stream.first;
      bloc.add(const ResetToDefaultRequested());
      final state = await reset;

      expect(state.errors.keys, [NetworkField.symbol]);

      await bloc.close();
    });

    test("a manual network has no default, so Reset does nothing", () async {
      final bloc = createBloc(devnet);
      await opened(bloc);
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      bloc.add(const ResetToDefaultRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(presented, isEmpty);
      expect(bloc.state.value(NetworkField.name), "Devnet");

      await subscription.cancel();
      await bloc.close();
    });
  });

  group("delete", () {
    test("a manual network with no wallets or contacts can be deleted", () async {
      when(() => networkService.delete(any())).thenAnswer((_) async {});
      final bloc = createBloc(devnet);
      final state = await opened(bloc);
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      expect(state.canDelete, isTrue);
      bloc.add(const NetworkDeleteConfirmed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => networkService.delete(devnet)).called(1);
      expect(presented, [isA<NetworkDetailsDeleted>()]);

      await subscription.cancel();
      await bloc.close();
    });

    test("a refusal from the service shows the fresh counts and does not pop", () async {
      when(() => networkService.delete(any()))
          .thenThrow(const NetworkInUseException(walletCount: 1, contactCount: 3));
      final bloc = createBloc(devnet);
      await opened(bloc);
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      final refused = bloc.stream.first;
      bloc.add(const NetworkDeleteConfirmed());
      final state = await refused;

      expect(state.walletCount, 1);
      expect(state.contactCount, 3);
      expect(state.canDelete, isFalse);
      expect(presented, isEmpty);

      await subscription.cancel();
      await bloc.close();
    });

    test("any other delete failure is presented", () async {
      when(() => networkService.delete(any())).thenThrow(StateError("database is locked"));
      final bloc = createBloc(devnet);
      await opened(bloc);
      final presented = <NetworkDetailsPresentation>[];
      final subscription = bloc.presentation.listen(presented.add);

      bloc.add(const NetworkDeleteConfirmed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(presented, [isA<NetworkDetailsFailed>()]);

      await subscription.cancel();
      await bloc.close();
    });

    test("delete is offered only for a manual network with no wallets or contacts", () async {
      when(() => networkService.walletCount(devnet.chainId)).thenAnswer((_) async => 1);
      final withWallets = createBloc(devnet);
      expect((await opened(withWallets)).canDelete, isFalse);
      await withWallets.close();

      final chainList = createBloc(ink);
      expect((await opened(chainList)).canDelete, isFalse);
      await chainList.close();

      final adding = createBloc(null);
      expect(adding.state.canDelete, isFalse);
      expect((await opened(adding)).canDelete, isFalse);
      await adding.close();
    });

    test("confirming delete in add mode calls nothing", () async {
      final bloc = createBloc(null);
      await opened(bloc);

      bloc.add(const NetworkDeleteConfirmed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verifyNever(() => networkService.delete(any()));
      await bloc.close();
    });
  });
}
