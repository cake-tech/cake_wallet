import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

const newCakeWalletMoneroUri = 'xmr-node.cakewallet.com:18081';
const cakeWalletBitcoinElectrumUri = 'electrum.cakewallet.com:50002';
const cakeWalletLitecoinElectrumUri = 'ltc-electrum.cakewallet.com:50002';

Future<void> changeMoneroCurrentNodeToDefault(
    {@required SharedPreferences sharedPreferences,
    @required Box<Node> nodes}) async {
  final node = getMoneroDefaultNode(nodes: nodes);
  final nodeId = node?.key as int ?? 0; // 0 - England

  await sharedPreferences.setInt('current_node_id', nodeId);
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

  return nodes.values.firstWhere((Node node) => node.uri.toString() == nodeUri,
          orElse: () => null) ??
      nodes.values.first;
}

Future<void> changeBitcoinCurrentElectrumServerToDefault(
    {@required SharedPreferences sharedPreferences,
    @required Box<Node> nodes}) async {
  final server = getBitcoinDefaultElectrumServer(nodes: nodes);
  final serverId = server?.key as int ?? 0;

  await sharedPreferences.setInt('current_node_id_btc', serverId);
}

Node getBitcoinDefaultElectrumServer({@required Box<Node> nodes}) {
  return nodes.values.firstWhere(
          (Node node) => node.uri.toString() == cakeWalletBitcoinElectrumUri,
          orElse: () => null) ??
      nodes.values.firstWhere((node) => node.type == WalletType.bitcoin,
          orElse: () => null);
}

Node getLitecoinDefaultElectrumServer({@required Box<Node> nodes}) {
  return nodes.values.firstWhere(
          (Node node) => node.uri.toString() == cakeWalletLitecoinElectrumUri,
          orElse: () => null) ??
      nodes.values.firstWhere((node) => node.type == WalletType.litecoin,
          orElse: () => null);
}

Future<void> checkCurrentNodes(
    Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
  final currentMoneroNodeId =
      sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentBitcoinElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
  final currentLitecoinElectrumSeverId = sharedPreferences
      .getInt(PreferencesKey.currentLitecoinElectrumSererIdKey);
  final currentMoneroNode = nodeSource.values.firstWhere(
      (node) => node.key == currentMoneroNodeId,
      orElse: () => null);
  final currentBitcoinElectrumServer = nodeSource.values.firstWhere(
      (node) => node.key == currentBitcoinElectrumSeverId,
      orElse: () => null);
  final currentLitecoinElectrumServer = nodeSource.values.firstWhere(
      (node) => node.key == currentLitecoinElectrumSeverId,
      orElse: () => null);

  if (currentMoneroNode == null) {
    final newCakeWalletNode =
        Node(uri: newCakeWalletMoneroUri, type: WalletType.monero);
    await nodeSource.add(newCakeWalletNode);
    await sharedPreferences.setInt(
        PreferencesKey.currentNodeIdKey, newCakeWalletNode.key as int);
  }

  if (currentBitcoinElectrumServer == null) {
    final cakeWalletElectrum =
        Node(uri: cakeWalletBitcoinElectrumUri, type: WalletType.bitcoin);
    await nodeSource.add(cakeWalletElectrum);
    await sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey,
        cakeWalletElectrum.key as int);
  }

  if (currentLitecoinElectrumServer == null) {
    final cakeWalletElectrum =
        Node(uri: cakeWalletLitecoinElectrumUri, type: WalletType.litecoin);
    await nodeSource.add(cakeWalletElectrum);
    await sharedPreferences.setInt(
        PreferencesKey.currentLitecoinElectrumSererIdKey,
        cakeWalletElectrum.key as int);
  }
}
