import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import "package:yaml/yaml.dart";
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';

Future<List<Node>> loadDefaultNodes() async {
  final nodesRaw = await rootBundle.loadString('assets/node_list.yml');
  final loadedNodes = loadYaml(nodesRaw) as YamlList;
  final nodes = <Node>[];

  for (final raw in loadedNodes) {
    if (raw is Map) {
      final node = Node.fromMap(Map<String, Object>.from(raw));
      node.type = WalletType.monero;
      nodes.add(node);
    }
  }

  return nodes;
}

Future<List<Node>> loadBitcoinElectrumServerList() async {
  final serverListRaw =
      await rootBundle.loadString('assets/bitcoin_electrum_server_list.yml');
  final loadedServerList = loadYaml(serverListRaw) as YamlList;
  final serverList = <Node>[];

  for (final raw in loadedServerList) {
     if (raw is Map) {
      final node = Node.fromMap(Map<String, Object>.from(raw));
      node.type = WalletType.bitcoin;
      serverList.add(node);
    }
  }

  return serverList;
}

Future<List<Node>> loadLitecoinElectrumServerList() async {
  final serverListRaw =
      await rootBundle.loadString('assets/litecoin_electrum_server_list.yml');
  final loadedServerList = loadYaml(serverListRaw) as YamlList;
  final serverList = <Node>[];

  for (final raw in loadedServerList) {
    if (raw is Map) {
      final node = Node.fromMap(Map<String, Object>.from(raw));
      node.type = WalletType.litecoin;
      serverList.add(node);
    }
  }

  return serverList;
}

Future<List<Node>> loadDefaultHavenNodes() async {
  final nodesRaw = await rootBundle.loadString('assets/haven_node_list.yml');
  final loadedNodes = loadYaml(nodesRaw) as YamlList;
  final nodes = <Node>[];

  for (final raw in loadedNodes) {
    if (raw is Map) {
      final node = Node.fromMap(Map<String, Object>.from(raw));
      node.type = WalletType.haven;
      nodes.add(node);
    }
  }
  
  return nodes;
}

Future resetToDefault(Box<Node> nodeSource) async {
  final moneroNodes = await loadDefaultNodes();
  final bitcoinElectrumServerList = await loadBitcoinElectrumServerList();
  final litecoinElectrumServerList = await loadLitecoinElectrumServerList();
  final havenNodes = await loadDefaultHavenNodes();
  final nodes =
      moneroNodes +
      bitcoinElectrumServerList +
      litecoinElectrumServerList +
      havenNodes;

  await nodeSource.clear();
  await nodeSource.addAll(nodes);
}
