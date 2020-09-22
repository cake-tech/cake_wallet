import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';

Future defaultSettingsMigration(
    {@required int version,
    @required SharedPreferences sharedPreferences,
    @required Box<Node> nodes}) async {
  final currentVersion =
      sharedPreferences.getInt('current_default_settings_migration_version') ??
          0;
  if (currentVersion >= version) {
    return;
  }

  final migrationVersionsLength = version - currentVersion;
  final migrationVersions = List<int>.generate(
      migrationVersionsLength, (i) => currentVersion + (i + 1));

  await Future.forEach(migrationVersions, (int version) async {
    try {
      switch (version) {
        case 1:
          await sharedPreferences.setString(
              PreferencesKey.currentFiatCurrencyKey,
              FiatCurrency.usd.toString());
          await sharedPreferences.setInt(
              PreferencesKey.currentTransactionPriorityKey,
              TransactionPriority.standart.raw);
          await sharedPreferences.setInt(
              PreferencesKey.currentBalanceDisplayModeKey,
              BalanceDisplayMode.availableBalance.raw);
          await sharedPreferences.setBool('save_recipient_address', true);
          await resetToDefault(nodes);
          await changeMoneroCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          await changeBitcoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);

          break;
        case 2:
          await replaceNodesMigration(nodes: nodes);
          await replaceDefaultNode(
              sharedPreferences: sharedPreferences, nodes: nodes);

          break;
        case 3:
          await updateNodeTypes(nodes: nodes);
          await addBitcoinElectrumServerList(nodes: nodes);

          break;
        case 4:
          await changeBitcoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          break;
        default:
          break;
      }

      await sharedPreferences.setInt(
          'current_default_settings_migration_version', version);
    } catch (e) {
      print('Migration error: ${e.toString()}');
    }
  });

  await sharedPreferences.setInt(
      'current_default_settings_migration_version', version);
}

Future<void> replaceNodesMigration({@required Box<Node> nodes}) async {
  final replaceNodes = <String, Node>{
    'eu-node.cakewallet.io:18081':
        Node(uri: 'xmr-node-eu.cakewallet.com:18081', type: WalletType.monero),
    'node.cakewallet.io:18081': Node(
        uri: 'xmr-node-usa-east.cakewallet.com:18081', type: WalletType.monero),
    'node.xmr.ru:13666':
        Node(uri: 'node.monero.net:18081', type: WalletType.monero)
  };

  nodes.values.forEach((Node node) async {
    final nodeToReplace = replaceNodes[node.uri];

    if (nodeToReplace != null) {
      node.uri = nodeToReplace.uri;
      node.login = nodeToReplace.login;
      node.password = nodeToReplace.password;
      await node.save();
    }
  });
}

Future<void> changeMoneroCurrentNodeToDefault(
    {@required SharedPreferences sharedPreferences,
    @required Box<Node> nodes}) async {
  final node = getMoneroDefaultNode(nodes: nodes);
  final nodeId = node?.key as int ?? 0; // 0 - England

  await sharedPreferences.setInt('current_node_id', nodeId);
}

Node getBitcoinDefaultElectrumServer({@required Box<Node> nodes}) {
  final uri = 'electrumx.cakewallet.com:50002';

  return nodes.values
          .firstWhere((Node node) => node.uri == uri, orElse: () => null) ??
      nodes.values.firstWhere((node) => node.type == WalletType.bitcoin,
          orElse: () => null);
}

Node getMoneroDefaultNode({@required Box<Node> nodes}) {
  final timeZone = DateTime.now().timeZoneOffset.inHours;
  var nodeUri = '';

  if (timeZone >= 1) {
    // Eurasia
    nodeUri = 'xmr-node-eu.cakewallet.com:18081';
  } else if (timeZone <= -4) {
    // America
    nodeUri = 'xmr-node-usa-east.cakewallet.com:18081';
  }

  return nodes.values
          .firstWhere((Node node) => node.uri == nodeUri, orElse: () => null) ??
      nodes.values.first;
}

Future<void> changeBitcoinCurrentElectrumServerToDefault(
    {@required SharedPreferences sharedPreferences,
    @required Box<Node> nodes}) async {
  final server = getBitcoinDefaultElectrumServer(nodes: nodes);
  final serverId = server?.key as int ?? 0;

  await sharedPreferences.setInt('current_node_id_btc', serverId);
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

Future<void> updateNodeTypes({@required Box<Node> nodes}) async {
  nodes.values.forEach((node) async {
    if (node.type == null) {
      node.type = WalletType.monero;
      await node.save();
    }
  });
}

Future<void> addBitcoinElectrumServerList({@required Box<Node> nodes}) async {
  final serverList = await loadElectrumServerList();
  await nodes.addAll(serverList);
}
