import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/migrations/commons.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationV15 {
  static Future<void> run() async {
    final nodes = getIt.get<Box<Node>>();
    final sharedPreferences = getIt.get<SharedPreferences>();
    await addLitecoinElectrumServerList(nodes: nodes);
    await changeLitecoinCurrentElectrumServerToDefault(
        sharedPreferences: sharedPreferences, nodes: nodes);
    await checkCurrentNodes(nodes, sharedPreferences);
  }

  static Future<void> addLitecoinElectrumServerList(
      {@required Box<Node> nodes}) async {
    final serverList = await loadLitecoinElectrumServerList();
    await nodes.addAll(serverList);
  }

  static Future<void> changeLitecoinCurrentElectrumServerToDefault(
      {@required SharedPreferences sharedPreferences,
      @required Box<Node> nodes}) async {
    final server = getLitecoinDefaultElectrumServer(nodes: nodes);
    final serverId = server?.key as int ?? 0;

    await sharedPreferences.setInt('current_node_id_ltc', serverId);
  }

  Future<void> replaceDefaultNode(
      {@required SharedPreferences sharedPreferences,
      @required Box<Node> nodes}) async {
    const nodesForReplace = <String>[
      'xmr-node-uk.cakewallet.com:18081',
      'eu-node.cakewallet.io:18081',
      'node.cakewallet.io:18081'
    ];
    final currentNodeId = sharedPreferences.getInt('current_node_id');
    final currentNode =
        nodes.values.firstWhere((Node node) => node.key == currentNodeId);
    final needToReplace =
        currentNode == null ? true : nodesForReplace.contains(currentNode.uri);

    if (!needToReplace) {
      return;
    }

    await changeMoneroCurrentNodeToDefault(
        sharedPreferences: sharedPreferences, nodes: nodes);
  }
}
