import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import "package:yaml/yaml.dart";
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

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

Future<List<Node>> loadElectrumServerList() async {
  final serverListRaw =
      await rootBundle.loadString('assets/electrum_server_list.yml');
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

Future resetToDefault(Box<Node> nodeSource) async {
  final moneroNodes = await loadDefaultNodes();
  // final bitcoinElectrumServerList = await loadElectrumServerList();
  // final nodes = moneroNodes + bitcoinElectrumServerList;

  await nodeSource.clear();
  await nodeSource.addAll(moneroNodes);
}
