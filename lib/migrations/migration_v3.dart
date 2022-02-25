import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class MigrationV3 {
  static Future<void> run() async {
    final nodes = getIt.get<Box<Node>>();
    await updateNodeTypes(nodes: nodes);
    await addBitcoinElectrumServerList(nodes: nodes);
  }

  static Future<void> updateNodeTypes({@required Box<Node> nodes}) async {
    nodes.values.forEach((node) async {
      if (node.type == null) {
        node.type = WalletType.monero;
        await node.save();
      }
    });
  }

  static Future<void> addBitcoinElectrumServerList(
      {@required Box<Node> nodes}) async {
    final serverList = await loadBitcoinElectrumServerList();
    await nodes.addAll(serverList);
  }
}
