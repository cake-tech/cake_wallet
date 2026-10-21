import "package:cake_wallet/reactions/on_current_node_change.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/node.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableMap;
import "package:mocktail/mocktail.dart";

class _MockAppStore extends Mock implements AppStore {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

void main() {
  const walletChainId = 57073;
  const otherChainId = 25;

  late _MockAppStore appStore;
  late _MockWallet wallet;
  late ObservableMap<WalletType, Node> nodes;
  late ObservableMap<int, Node> evmChainNodes;

  setUpAll(() => registerFallbackValue(Node(uri: "fallback.example", type: WalletType.evm)));

  setUp(() {
    appStore = _MockAppStore();
    final settingsStore = _MockSettingsStore();
    wallet = _MockWallet();
    nodes = ObservableMap<WalletType, Node>();
    evmChainNodes = ObservableMap<int, Node>();

    when(() => appStore.settingsStore).thenReturn(settingsStore);
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => settingsStore.nodes).thenReturn(nodes);
    when(() => settingsStore.evmChainNodes).thenReturn(evmChainNodes);
    when(() => settingsStore.powNodes).thenReturn(ObservableMap<WalletType, Node>());
    when(() => wallet.type).thenReturn(WalletType.evm);
    when(() => wallet.chainId).thenReturn(walletChainId);
    when(() => wallet.connectToNode(node: any(named: "node"))).thenAnswer((_) async {});
  });

  group("startOnCurrentNodeChangeReaction", () {
    test("starting it twice reconnects once per node change, not twice", () async {
      startOnCurrentNodeChangeReaction(appStore);
      startOnCurrentNodeChangeReaction(appStore);
      final node = Node(uri: "ink-rpc.example", type: WalletType.evm, chainId: walletChainId);

      evmChainNodes[walletChainId] = node;
      await Future<void>.delayed(Duration.zero);

      verify(() => wallet.connectToNode(node: node)).called(1);
    });

    test("a restart also drops the old observer of the built-in nodes", () async {
      when(() => wallet.type).thenReturn(WalletType.ethereum);
      startOnCurrentNodeChangeReaction(appStore);
      startOnCurrentNodeChangeReaction(appStore);
      final node = Node(uri: "eth-rpc.example", type: WalletType.ethereum);

      nodes[WalletType.ethereum] = node;
      await Future<void>.delayed(Duration.zero);

      verify(() => wallet.connectToNode(node: node)).called(1);
    });

    test("a node change on another added chain does not reconnect the wallet", () async {
      startOnCurrentNodeChangeReaction(appStore);

      evmChainNodes[otherChainId] =
          Node(uri: "cronos-rpc.example", type: WalletType.evm, chainId: otherChainId);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => wallet.connectToNode(node: any(named: "node")));
    });

    test("an added chain's node change does not reconnect a built-in wallet", () async {
      when(() => wallet.type).thenReturn(WalletType.ethereum);
      when(() => wallet.chainId).thenReturn(1);
      startOnCurrentNodeChangeReaction(appStore);

      // Keyed on the wallet's own chain ID, so only the wallet type check stops the reconnect
      evmChainNodes[1] = Node(uri: "eth-rpc.example", type: WalletType.evm, chainId: 1);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => wallet.connectToNode(node: any(named: "node")));
    });
  });
}
