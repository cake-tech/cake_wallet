import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';

part 'node_list_view_model.g.dart';

class NodeListViewModel = NodeListViewModelBase with _$NodeListViewModel;

abstract class NodeListViewModelBase with Store {
  NodeListViewModelBase(this._nodeSource, this._appStore)
      : nodes = ObservableList<Node>(),
        settingsStore = _appStore.settingsStore {
    _bindNodes();

    reaction((_) => _appStore.wallet, (WalletBase? _wallet) {
      _bindNodes();
    });

    reaction((_) {
      final wallet = _appStore.wallet;
      if (wallet != null && isEVMCompatibleChain(wallet.type)) {
        // Access selectedChainId to track changes
        return evm!.getSelectedChainId(wallet);
      }
      return null;
    }, (_) {
      _bindNodes();
    });
  }

  @computed
  Node get currentNode {
    final wallet = _appStore.wallet!;
    final walletType = wallet.type;

    int? chainId;
    if (isEVMCompatibleChain(walletType)) {
      chainId = evm!.getSelectedChainId(wallet);
    }

    if (isEVMCompatibleChain(walletType) && chainId != null) {
      return settingsStore.getCurrentNode(walletType, chainId: chainId);
    }

    final node = settingsStore.nodes[walletType];
    if (node == null) {
      throw Exception('No node for wallet type: $walletType');
    }
    return node;
  }

  String getAlertContent(String uri) =>
      S.current.change_current_node(uri) +
      '${uri.endsWith('.onion') || uri.contains('.onion:') ? '\n' + (CakeTor.instance!.enabled ? '' : S.current.orbot_running_alert) : ''}';

  @computed
  bool get enableAutomaticNodeSwitching => settingsStore.enableAutomaticNodeSwitching;

  @action
  void setEnableAutomaticNodeSwitching(bool value) =>
      settingsStore.enableAutomaticNodeSwitching = value;

  final ObservableList<Node> nodes;
  final SettingsStore settingsStore;
  final Box<Node> _nodeSource;
  final AppStore _appStore;

  Future<void> reset() async {
    await resetToDefault(_nodeSource);

    final wallet = _appStore.wallet!;
    final walletType = wallet.type;

    Node node;
    if (walletType == WalletType.bitcoin && wallet.isTestnet) {
      node = getBitcoinTestnetDefaultElectrumServer(nodes: _nodeSource)!;
    } else if (isEVMCompatibleChain(walletType)) {
      final chainId = evm!.getSelectedChainId(wallet);
      if (chainId != null) {
        final nodeWalletType = evm!.getWalletTypeByChainId(chainId);
        if (nodeWalletType != null) {
          node = getDefaultNode(nodes: _nodeSource, type: nodeWalletType)!;
        } else {
          throw Exception(
              'Cannot reset node for EVM wallet: wallet type not found for chainId: $chainId');
        }
      } else {
        throw Exception('Cannot reset node for EVM wallet: chainId is null');
      }
    } else {
      node = getDefaultNode(nodes: _nodeSource, type: walletType)!;
    }

    await setAsCurrent(node);
  }

  @action
  Future<void> delete(Node node) async => node.delete();

  @action
  Future<void> setAsCurrent(Node node) async {
    final wallet = _appStore.wallet!;
    final walletType = wallet.type;

    if (isEVMCompatibleChain(walletType)) {
      final chainId = evm!.getSelectedChainId(wallet);
      if (chainId != null) {
        final nodeWalletType = evm!.getWalletTypeByChainId(chainId);
        if (nodeWalletType != null) {
          settingsStore.nodes[nodeWalletType] = node;
          return;
        }
      }
      throw Exception('Cannot set node for EVM wallet: chainId or wallet type not found');
    }

    // For non-EVM wallets, use the wallet type directly
    settingsStore.nodes[walletType] = node;
  }

  @action
  void _bindNodes() {
    nodes.clear();
    final wallet = _appStore.wallet!;
    final walletType = wallet.type;

    // We filter nodes by the wallet type corresponding to current chainId for EVM wallets
    if (isEVMCompatibleChain(walletType)) {
      final chainId = evm!.getSelectedChainId(wallet);
      if (chainId != null) {
        final nodeWalletType = evm!.getWalletTypeByChainId(chainId);
        if (nodeWalletType != null) {
          _nodeSource.bindToList(
            nodes,
            filter: (val) => val.type == nodeWalletType,
            initialFire: true,
          );
          return;
        }
      }
      // If chainId is null or wallet type not found, show no nodes
      return;
    }

    // For non-EVM wallets, use the wallet type directly
    _nodeSource.bindToList(
      nodes,
      filter: (val) => val.type == walletType,
      initialFire: true,
    );
  }
}
