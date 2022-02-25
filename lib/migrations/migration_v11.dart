import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/migrations/commons.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationV11 {
  static Future<void> run() async {
    final nodes = getIt.get<Box<Node>>();
    final sharedPreferences = getIt.get<SharedPreferences>();
    await changeDefaultMoneroNode(nodes, sharedPreferences);
  }

  static Future<void> changeDefaultMoneroNode(
      Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
    const cakeWalletMoneroNodeUriPattern = '.cakewallet.com';
    final currentMoneroNodeId =
        sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
    final currentMoneroNode =
        nodeSource.values.firstWhere((node) => node.key == currentMoneroNodeId);
    final needToReplaceCurrentMoneroNode = currentMoneroNode.uri
        .toString()
        .contains(cakeWalletMoneroNodeUriPattern);

    nodeSource.values.forEach((node) async {
      if (node.type == WalletType.monero &&
          node.uri.toString().contains(cakeWalletMoneroNodeUriPattern)) {
        await node.delete();
      }
    });

    final newCakeWalletNode =
        Node(uri: newCakeWalletMoneroUri, type: WalletType.monero);

    await nodeSource.add(newCakeWalletNode);

    if (needToReplaceCurrentMoneroNode) {
      await sharedPreferences.setInt(
          PreferencesKey.currentNodeIdKey, newCakeWalletNode.key as int);
    }
  }
}
