import 'dart:async';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/utils/mobx.dart';

part 'node_list_store.g.dart';

class NodeListStore = NodeListStoreBase with _$NodeListStore;

abstract class NodeListStoreBase with Store {
  NodeListStoreBase() : nodes = ObservableList<Node>();

  static StreamSubscription<BoxEvent> _onNodesSourceChange;
  static NodeListStore _instance;

  static NodeListStore get instance {
    if (_instance != null) {
      return _instance;
    }

    final nodeSource = getIt.get<Box<Node>>();
    _instance = NodeListStore();
    _instance.replaceValues(nodeSource.values);
    _onNodesSourceChange?.cancel();
    _onNodesSourceChange = bindBox(nodeSource, _instance.nodes);

    return _instance;
  }

  final ObservableList<Node> nodes;

  void replaceValues(Iterable<Node> newNodes) {
    nodes.clear();
    nodes.addAll(newNodes);
  }
}
