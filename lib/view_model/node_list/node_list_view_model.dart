import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/node_list.dart';
import 'package:cake_wallet/store/node_list_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/src/domain/common/default_settings_migration.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cake_wallet/utils/item_cell.dart';

part 'node_list_view_model.g.dart';

class NodeListViewModel = NodeListViewModelBase with _$NodeListViewModel;

abstract class NodeListViewModelBase with Store {
  NodeListViewModelBase(
      this._nodeListStore, this._nodeSource, this._wallet, this._settingsStore)
      : nodes = ObservableList<ItemCell<Node>>() {
    final currentNode = _settingsStore.getCurrentNode(_wallet.type);
    final values = _nodeListStore.nodes;
    nodes.clear();
    nodes.addAll(values.where((Node node) => node.type == _wallet.type).map(
        (Node val) => ItemCell<Node>(val,
            isSelected: val.key == currentNode.key, key: val.key)));
    connectDifferent(
        _nodeListStore.nodes,
        nodes,
        (Node val) => ItemCell<Node>(val,
            isSelected: val.key == currentNode.key, key: val.key),
        filter: (Node val) => val.type == _wallet.type);
    reaction((_) => _settingsStore.nodes[_wallet.type],
        (Node _) => _updateCurrentNode());
  }

  ObservableList<ItemCell<Node>> nodes;

  final WalletBase _wallet;
  final Box<Node> _nodeSource;
  final NodeListStore _nodeListStore;
  final SettingsStore _settingsStore;

  Future<void> reset() async {
    await resetToDefault(_nodeSource);

    Node node;

    switch (_wallet.type) {
      case WalletType.bitcoin:
        node = getBitcoinDefaultElectrumServer(nodes: _nodeSource);
        break;
      case WalletType.monero:
        node = getMoneroDefaultNode(
          nodes: _nodeSource,
        );
        break;
      default:
        break;
    }

    await setAsCurrent(node);
  }

  Future<void> delete(Node node) async => _nodeSource.delete(node.key);

  Future<void> setAsCurrent(Node node) async {
    await _settingsStore.setCurrentNode(node, _wallet.type);
    _updateCurrentNode();
    await _wallet.connectToNode(node: node);
  }

  @action
  void _updateCurrentNode() {
    final currentNode = _settingsStore.getCurrentNode(_wallet.type);

    for (var i = 0; i < nodes.length; i++) {
      final item = nodes[i];
      final isSelected = item.value.key == currentNode.key;

      if (item.isSelected != isSelected) {
        nodes[i] = ItemCell<Node>(item.value,
            isSelected: isSelected, key: item.keyIndex);
      }
    }
  }
}
