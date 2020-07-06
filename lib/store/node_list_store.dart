import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/node.dart';

part 'node_list_store.g.dart';

class NodeListStore = NodeListStoreBase with _$NodeListStore;

abstract class NodeListStoreBase with Store {
  NodeListStoreBase() : nodes = ObservableList<Node>();

  final ObservableList<Node> nodes;

  void replaceValues(Iterable<Node> newNodes) {
    nodes.clear();
    nodes.addAll(newNodes);
  }
}
