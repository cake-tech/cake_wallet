import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import "package:yaml/yaml.dart";
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';

Future<List<Node>> loadDefaultNodes() async {
  final nodesRaw = await rootBundle.loadString('assets/node_list.yml');
  final nodes = loadYaml(nodesRaw) as YamlList;

  return nodes.map((dynamic raw) {
    if (raw is Map) {
      final node = Node.fromMap(raw);
      node?.type = WalletType.monero;

      return node;
    }

    return null;
  }).toList();
}

Future<List<Node>> loadBitcoinElectrumServerList() async {
  final serverListRaw =
      await rootBundle.loadString('assets/bitcoin_electrum_server_list.yml');
  final serverList = loadYaml(serverListRaw) as YamlList;

  return serverList.map((dynamic raw) {
    if (raw is Map) {
      final node = Node.fromMap(raw);
      node?.type = WalletType.bitcoin;

      return node;
    }

    return null;
  }).toList();
}

Future<List<Node>> loadLitecoinElectrumServerList() async {
  final serverListRaw =
      await rootBundle.loadString('assets/litecoin_electrum_server_list.yml');
  final serverList = loadYaml(serverListRaw) as YamlList;

  return serverList.map((dynamic raw) {
    if (raw is Map) {
      final node = Node.fromMap(raw);
      node?.type = WalletType.litecoin;

      return node;
    }

    return null;
  }).toList();
}

Future<List<Node>> loadDefaultHavenNodes() async {
  final nodesRaw = await rootBundle.loadString('assets/haven_node_list.yml');
  final nodes = loadYaml(nodesRaw) as YamlList;

  return nodes.map((dynamic raw) {
    if (raw is Map) {
      final node = Node.fromMap(raw);
      node?.type = WalletType.haven;

      return node;
    }

    return null;
  }).toList();
}

Future<List<Node>> loadDefaultWowneroNodes() async {
  final nodesRaw = await rootBundle.loadString('assets/wownero_node_list.yml');
  final nodes = loadYaml(nodesRaw) as YamlList;

  return nodes.map((dynamic raw) {
    if (raw is Map) {
      final node = Node.fromMap(raw);
      node?.type = WalletType.wownero;

      return node;
    }

    return null;
  }).toList();
}

Future resetToDefault(Box<Node> nodeSource) async {
  final moneroNodes = await loadDefaultNodes();
  final bitcoinElectrumServerList = await loadBitcoinElectrumServerList();
  final litecoinElectrumServerList = await loadLitecoinElectrumServerList();
  final havenNodes = await loadDefaultHavenNodes();
  final wowneroNodes = await loadDefaultWowneroNodes();
  final nodes =
      moneroNodes +
      bitcoinElectrumServerList +
      litecoinElectrumServerList +
      havenNodes +
      wowneroNodes;

  await nodeSource.clear();
  await nodeSource.addAll(nodes);
}
