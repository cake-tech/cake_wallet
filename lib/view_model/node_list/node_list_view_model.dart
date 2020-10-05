import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/utils/mobx.dart';

part 'node_list_view_model.g.dart';

class NodeListViewModel = NodeListViewModelBase with _$NodeListViewModel;

abstract class NodeListViewModelBase with Store {
  NodeListViewModelBase(this._nodeSource, this._wallet, this.settingsStore)
      : nodes = ObservableList<Node>() {
    _nodeSource.bindToList(nodes,
        filter: (Node val) => val?.type == _wallet.type, initialFire: true);
  }

  final ObservableList<Node> nodes;
  final SettingsStore settingsStore;

  final WalletBase _wallet;
  final Box<Node> _nodeSource;

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

  @action
  Future<void> delete(Node node) async => node.delete();

  Future<void> setAsCurrent(Node node) async =>
      settingsStore.currentNode = node;
}
