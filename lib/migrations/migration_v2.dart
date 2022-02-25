import 'package:cake_wallet/di.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'commons.dart';

class MigrationV2 {
  static Future<void> run() async {
    final nodes = getIt.get<Box<Node>>();
    final sharedPreferences = getIt.get<SharedPreferences>();
    await replaceNodesMigration(nodes: nodes);
    await replaceDefaultNode(
        sharedPreferences: sharedPreferences, nodes: nodes);
  }

  static Future<void> replaceNodesMigration({@required Box<Node> nodes}) async {
    final replaceNodes = <String, Node>{
      'eu-node.cakewallet.io:18081': Node(
          uri: 'xmr-node-eu.cakewallet.com:18081', type: WalletType.monero),
      'node.cakewallet.io:18081': Node(
          uri: 'xmr-node-usa-east.cakewallet.com:18081',
          type: WalletType.monero),
      'node.xmr.ru:13666':
          Node(uri: 'node.monero.net:18081', type: WalletType.monero)
    };

    nodes.values.forEach((Node node) async {
      final nodeToReplace = replaceNodes[node.uri];

      if (nodeToReplace != null) {
        node.uriRaw = nodeToReplace.uriRaw;
        node.login = nodeToReplace.login;
        node.password = nodeToReplace.password;
        await node.save();
      }
    });
  }

  static Future<void> replaceDefaultNode(
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
