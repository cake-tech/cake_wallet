import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/wallet_network_bloc.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableMap, ObservableSet;
import "package:mocktail/mocktail.dart";

class _MockSettingsStore extends Mock implements SettingsStore {}

ChainInfo _addedChain({
  required int chainId,
  required String name,
  required String symbol,
  required ChainSource source,
  String? iconPath,
}) {
  final network = EvmNetwork(
    chainId: chainId,
    name: name,
    symbol: symbol,
    decimals: 18,
    tag: symbol,
    rpcUrl: "https://rpc.$chainId.example",
    iconUrl: iconPath,
    isManual: source == ChainSource.manual,
    isEnabled: true,
  );

  return ChainInfo(
    chainId: chainId,
    name: name,
    shortCode: "evm$chainId",
    currency: AddedNetworkCurrency(network),
    source: source,
    iconPath: iconPath,
  );
}

void main() {
  const ethereumChain = ChainInfo(
    chainId: 1,
    name: "Ethereum",
    shortCode: "eth",
    currency: CryptoCurrency.eth,
    source: ChainSource.builtin,
  );
  const inkIcon = "assets/new-ui/network_icons/ink.svg";

  late _MockSettingsStore settingsStore;
  late ChainInfo ink;
  late ChainInfo manualChain;

  setUp(() {
    settingsStore = _MockSettingsStore();
    ink = _addedChain(
      chainId: 57073,
      name: "Ink",
      symbol: "INKETH",
      source: ChainSource.chainlist,
      iconPath: inkIcon,
    );
    manualChain = _addedChain(
      chainId: 777001,
      name: "My Devnet",
      symbol: "DEV",
      source: ChainSource.manual,
    );
    when(() => settingsStore.hiddenBuiltinNetworks).thenReturn(ObservableSet<WalletType>());
    when(() => settingsStore.evmNetworks).thenReturn(ObservableMap<int, ChainInfo>());
  });

  List<WalletType> getBuiltinTypes(WalletNetworkState state) =>
      state.builtinRows.map((row) => row.network.type).toList();

  group("WalletNetworkBloc", () {
    test("create, restore and restore from QR list the same rows", () {
      when(() => settingsStore.hiddenBuiltinNetworks)
          .thenReturn(ObservableSet.of({WalletType.zano}));
      when(() => settingsStore.evmNetworks).thenReturn(
        ObservableMap.of({1: ethereumChain, ink.chainId: ink}),
      );

      for (final mode in const [
        WalletNetworkCreate(),
        WalletNetworkRestore(),
        WalletNetworkRestoreFromQr(),
      ]) {
        final state = WalletNetworkBloc(mode, settingsStore).state;

        expect(
          getBuiltinTypes(state),
          builtinNetworkTypes.where((type) => type != WalletType.zano).toList(),
          reason: mode.runtimeType.toString(),
        );
        expect(
          state.addedRows.map((row) => row.network),
          [const WalletNetwork.added(57073)],
          reason: mode.runtimeType.toString(),
        );
      }
    });

    test("a built-in row carries its type with no chain ID, its name, symbol and icon", () {
      final state = WalletNetworkBloc(const WalletNetworkCreate(), settingsStore).state;

      final ethereum = state.builtinRows.singleWhere(
        (row) => row.network.type == WalletType.ethereum,
      );
      expect(ethereum.network.chainId, isNull);
      expect(ethereum.name, "Ethereum");
      expect(ethereum.symbol, "ETH");
      expect(ethereum.iconPath, "assets/new-ui/network_icons/ethereum.svg");
      expect(getBuiltinTypes(state), isNot(contains(WalletType.evm)));
    });

    test("hidden built-in networks are left out", () {
      when(() => settingsStore.hiddenBuiltinNetworks)
          .thenReturn(ObservableSet.of({WalletType.tron, WalletType.dogecoin}));

      final state = WalletNetworkBloc(const WalletNetworkCreate(), settingsStore).state;

      expect(getBuiltinTypes(state), isNot(contains(WalletType.tron)));
      expect(getBuiltinTypes(state), isNot(contains(WalletType.dogecoin)));
      expect(state.builtinRows, hasLength(builtinNetworkTypes.length - 2));
    });

    test("added networks are listed in the store's order, built-in chains are not", () {
      when(() => settingsStore.evmNetworks).thenReturn(
        ObservableMap.of({ink.chainId: ink, 1: ethereumChain, manualChain.chainId: manualChain}),
      );

      final state = WalletNetworkBloc(const WalletNetworkCreate(), settingsStore).state;

      expect(state.hasAddedNetworks, isTrue);
      expect(state.addedRows.map((row) => row.name), ["Ink", "My Devnet"]);

      final inkRow = state.addedRows.first;
      expect(inkRow.network, const WalletNetwork.added(57073));
      expect(inkRow.symbol, "INKETH");
      expect(inkRow.iconPath, inkIcon);
      expect(inkRow.isManual, isFalse);
      expect(state.addedRows.last.isManual, isTrue);
    });

    test("with no added network there are no added rows", () {
      when(() => settingsStore.evmNetworks).thenReturn(ObservableMap.of({1: ethereumChain}));

      final state = WalletNetworkBloc(const WalletNetworkCreate(), settingsStore).state;

      expect(state.addedRows, isEmpty);
      expect(state.hasAddedNetworks, isFalse);
    });

    test("a Ledger lists only the built-ins it supports, and the added networks", () {
      when(() => settingsStore.evmNetworks).thenReturn(ObservableMap.of({ink.chainId: ink}));

      final state = WalletNetworkBloc(
        const WalletNetworkHardware(HardwareWalletType.ledger),
        settingsStore,
      ).state;

      expect(
        getBuiltinTypes(state).toSet(),
        {
          WalletType.monero,
          WalletType.bitcoin,
          WalletType.litecoin,
          WalletType.ethereum,
          WalletType.polygon,
        },
      );
      expect(state.addedRows.map((row) => row.network.chainId), [57073]);
    });

    test("a Trezor gets no added rows but still knows added networks exist", () {
      when(() => settingsStore.evmNetworks).thenReturn(ObservableMap.of({ink.chainId: ink}));

      final state = WalletNetworkBloc(
        const WalletNetworkHardware(HardwareWalletType.trezor),
        settingsStore,
      ).state;

      expect(getBuiltinTypes(state), isNot(contains(WalletType.solana)));
      expect(getBuiltinTypes(state), contains(WalletType.ethereum));
      expect(state.addedRows, isEmpty);
      expect(state.hasAddedNetworks, isTrue);
    });

    test("a hidden network stays hidden in hardware mode too", () {
      when(() => settingsStore.hiddenBuiltinNetworks)
          .thenReturn(ObservableSet.of({WalletType.bitcoin}));

      final state = WalletNetworkBloc(
        const WalletNetworkHardware(HardwareWalletType.bitbox),
        settingsStore,
      ).state;

      expect(getBuiltinTypes(state).toSet(), {WalletType.ethereum, WalletType.polygon});
    });

    test("search matches the name or the symbol and keeps the rows", () async {
      when(() => settingsStore.evmNetworks).thenReturn(
        ObservableMap.of({ink.chainId: ink, manualChain.chainId: manualChain}),
      );
      final bloc = WalletNetworkBloc(const WalletNetworkCreate(), settingsStore);

      final byName = bloc.stream.first;
      bloc.add(const WalletNetworkSearchChanged("  devNET "));
      final state = await byName;

      expect(state.visibleAddedRows.map((row) => row.name), ["My Devnet"]);
      expect(state.visibleBuiltinRows, isEmpty);
      expect(state.addedRows, hasLength(2));

      final bySymbol = bloc.stream.first;
      bloc.add(const WalletNetworkSearchChanged("xmr"));
      final symbolState = await bySymbol;

      expect(symbolState.visibleBuiltinRows.map((row) => row.network.type), [WalletType.monero]);
      expect(symbolState.visibleAddedRows, isEmpty);

      await bloc.close();
    });

    test("refresh rebuilds the rows from the store and keeps the query", () async {
      final evmNetworks = ObservableMap<int, ChainInfo>();
      final hidden = ObservableSet<WalletType>();
      when(() => settingsStore.evmNetworks).thenReturn(evmNetworks);
      when(() => settingsStore.hiddenBuiltinNetworks).thenReturn(hidden);
      final bloc = WalletNetworkBloc(const WalletNetworkCreate(), settingsStore);

      final searched = bloc.stream.first;
      bloc.add(const WalletNetworkSearchChanged("ink"));
      await searched;

      evmNetworks[ink.chainId] = ink;
      hidden.add(WalletType.monero);
      final refreshed = bloc.stream.first;
      bloc.add(const WalletNetworkRefreshed());
      final state = await refreshed;

      expect(state.query, "ink");
      expect(state.visibleAddedRows.map((row) => row.name), ["Ink"]);
      expect(getBuiltinTypes(state), isNot(contains(WalletType.monero)));

      await bloc.close();
    });
  });
}
