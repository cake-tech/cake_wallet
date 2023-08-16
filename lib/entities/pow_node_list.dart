// import 'package:flutter/services.dart';
// import 'package:hive/hive.dart';
// import "package:yaml/yaml.dart";
// import 'package:cw_core/node.dart';
// import 'package:cw_core/wallet_type.dart';

// Future<List<Node>> loadDefaultNanoPowNodes() async {
//   final nodesRaw = await rootBundle.loadString('assets/nano_pow_node_list.yml');
//   final loadedNodes = loadYaml(nodesRaw) as YamlList;
//   final nodes = <Node>[];

//   for (final raw in loadedNodes) {
//     if (raw is Map) {
//       final node = Node.fromMap(Map<String, Object>.from(raw));
//       node.type = WalletType.nano;
//       nodes.add(node);
//     }
//   }

//   return nodes;
// }

// Future<List<Node>> loadDefaultBananoPowNodes() async {
//   final nodesRaw = await rootBundle.loadString('assets/nano_pow_node_list.yml');
//   final loadedNodes = loadYaml(nodesRaw) as YamlList;
//   final nodes = <Node>[];

//   for (final raw in loadedNodes) {
//     if (raw is Map) {
//       final node = Node.fromMap(Map<String, Object>.from(raw));
//       node.type = WalletType.banano;
//       nodes.add(node);
//     }
//   }

//   return nodes;
// }

// Future resetToDefault(Box<Node> nodeSource) async {
//   final nanoNodes = await loadDefaultNanoPowNodes();
//   final bananoNodes = await loadDefaultNanoPowNodes();
//   final nodes = nanoNodes + bananoNodes;

//   await nodeSource.clear();
//   await nodeSource.addAll(nodes);
// }
