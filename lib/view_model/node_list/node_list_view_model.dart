import 'dart:math';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/node_list.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';

part 'node_list_view_model.g.dart';

class NodeSpeed {
  final String iconPath;
  final String darkIconPath;

  // fraction of best node ping needed to be classified as this speed.
  final double treshold;

  const NodeSpeed._(this.iconPath, this.darkIconPath, this.treshold);

  static const disconnected = NodeSpeed._("assets/new-ui/node_speed_badges/disconnected.svg",
      "assets/new-ui/node_speed_badges/disconnected-dark.svg", 0);
  static const slow = NodeSpeed._("assets/new-ui/node_speed_badges/slow.svg",
      "assets/new-ui/node_speed_badges/slow-dark.svg", 0);
  static const medium = NodeSpeed._("assets/new-ui/node_speed_badges/medium.svg",
      "assets/new-ui/node_speed_badges/medium.svg", 0.5);
  static const fast = NodeSpeed._(
      "assets/new-ui/node_speed_badges/fast.svg", "assets/new-ui/node_speed_badges/fast.svg", 0.8);

  static const all = [fast, medium, slow, disconnected];
}

class NodeListViewModel = NodeListViewModelBase with _$NodeListViewModel;

abstract class NodeListViewModelBase with Store {
  NodeListViewModelBase(this._appStore, this.isPow)
      : nodes = ObservableList<Node>(),
        _nodeSpeeds = ObservableMap<String, int>(),
        settingsStore = _appStore.settingsStore {
    bindNodes();

    reaction((_) => _appStore.wallet, (WalletBase? _wallet) {
      bindNodes();
    });

    reaction((_) {
      final wallet = _appStore.wallet;
      if (wallet != null && isEVMCompatibleChain(wallet.type)) {
        // Access selectedChainId to track changes
        return evm!.getSelectedChainId(wallet);
      }
      return null;
    }, (_) {
      bindNodes();
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

    final node = isPow ? settingsStore.powNodes[walletType] : settingsStore.nodes[walletType];
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
  final AppStore _appStore;
  final bool isPow;
  final ObservableMap<String, int> _nodeSpeeds;

  @computed
  List<Node> get nonCurrentNodes => nodes.where((item) => item != currentNode).toList();

  @observable
  bool isTestingNodeSpeed = false;

  Future<void> speedTestNodes() async {
    try {
      isTestingNodeSpeed = true;
      _nodeSpeeds.clear();
      final nodes = this.nodes.toList();
      await Future.wait(nodes.map((node) async {
        final sw = Stopwatch()..start();
        final res =
            await node.requestNode().timeout(const Duration(seconds: 10), onTimeout: () => false);
        sw.stop();
        if (res) {
          _nodeSpeeds[node.uriRaw] = sw.elapsedMilliseconds;
        }
      }));
    } finally {
      isTestingNodeSpeed = false;
    }
  }

  NodeSpeed? nodeSpeedFor(Node node) {
    final bestSpeed = _bestNodeSpeed;
    final currentSpeed = _nodeSpeeds[node.uriRaw];
    if (bestSpeed == null) {
      return null;
    }
    if (currentSpeed == null) {
      return NodeSpeed.disconnected;
    }
    for (final speed in NodeSpeed.all) {
      if (currentSpeed < (bestSpeed / speed.treshold)) return speed;
    }

    return null;
  }

  int? get _bestNodeSpeed {
    try {
      printV(_nodeSpeeds);
      return _nodeSpeeds.values.reduce(min);
    } catch (e) {}
    return null;
  }

  Future<void> reset() async {
    await resetToDefault();

    final wallet = _appStore.wallet!;
    final walletType = wallet.type;

    Node node;
    if (walletType == WalletType.bitcoin && wallet.isTestnet) {
      node = (await getBitcoinTestnetDefaultElectrumServer())!;
    } else if (isEVMCompatibleChain(walletType)) {
      final chainId = evm!.getSelectedChainId(wallet);
      if (chainId != null) {
        final nodeWalletType = evm!.getWalletTypeByChainId(chainId);
        if (nodeWalletType != null) {
          node = (await Node.getDefaultForWalletType(nodeWalletType))!;
        } else {
          throw Exception(
              'Cannot reset node for EVM wallet: wallet type not found for chainId: $chainId');
        }
      } else {
        throw Exception('Cannot reset node for EVM wallet: chainId is null');
      }
    } else {
      node = (await Node.getDefaultForWalletType(_appStore.wallet!.type))!;
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
    if (isPow) {
      settingsStore.powNodes[walletType] = node;
    } else {
      settingsStore.nodes[walletType] = node;
    }
  }

  @action
  Future<void> bindNodes() async {
    nodes.clear();
    final wallet = _appStore.wallet!;
    final walletType = wallet.type;

    // We filter nodes by the wallet type corresponding to current chainId for EVM wallets
    if (isEVMCompatibleChain(walletType)) {
      final chainId = evm!.getSelectedChainId(wallet);
      if (chainId != null) {
        final nodeWalletType = evm!.getWalletTypeByChainId(chainId);
        if (nodeWalletType != null) {
          nodes.addAll(await Node.getAllForWalletType(nodeWalletType));

          return;
        }
      }
      // If chainId is null or wallet type not found, show no nodes
      return;
    }

    // For non-EVM wallets, use the wallet type directly
    nodes.addAll(isPow
        ? await Node.getAllForWalletTypePow(walletType)
        : await Node.getAllForWalletType(walletType));
  }
}
