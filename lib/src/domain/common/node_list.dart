import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import "package:yaml/yaml.dart";
import 'package:cake_wallet/src/domain/common/node.dart';

Future<List<Node>> loadDefaultNodes() async {
  final nodesRaw = await rootBundle.loadString('assets/node_list.yml');
  final nodes = loadYaml(nodesRaw) as List<Map<dynamic, dynamic>>;
  
  return nodes.map((raw) => Node.fromMap(raw)).toList();
}

Future resetToDefault(Box<Node> nodeSource) async {
  final nodes = await loadDefaultNodes();
  final enteties = Map<int, Node>();

  await nodeSource.clear();

  for (var i = 0; i < nodes.length; i++) {
    enteties[i] = nodes[i];
  }

  await nodeSource.putAll(enteties);
}
