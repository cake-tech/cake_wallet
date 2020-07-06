import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/node_list.dart';
import 'package:cake_wallet/store/node_list_store.dart';

part 'node_list_view_model.g.dart';

class NodeListViewModel = NodeListViewModelBase with _$NodeListViewModel;

abstract class NodeListViewModelBase with Store {
  NodeListViewModelBase(this._nodeListStore, this._nodeSource, this._wallet);

  @computed
  ObservableList<Node> get nodes => ObservableList<Node>.of(
      _nodeListStore.nodes.where((node) => node.type == _wallet.type));

  final WalletBase _wallet;
  final Box<Node> _nodeSource;
  final NodeListStore _nodeListStore;

  Future<void> reset() async => await resetToDefault(_nodeSource);

  Future<void> delete(Node node) async => node.delete();
}
