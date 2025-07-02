import 'dart:async';
import 'dart:developer';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NodeSwitchingService {
  NodeSwitchingService._internal() {
    _initializeNodeSource();
  }

  static NodeSwitchingService? _instance;

  factory NodeSwitchingService() {
    _instance ??= NodeSwitchingService._internal();
    return _instance!;
  }

  static NodeSwitchingService get instance {
    _instance ??= NodeSwitchingService._internal();
    return _instance!;
  }

  late Box<Node> nodeSource;
  late SharedPreferences sharedPreferences;

  // In-memory tracking of used nodes per wallet type
  final Map<WalletType, Set<int>> _usedNodeIds = {};

  Future<void> _initializeNodeSource() async {
    nodeSource = await CakeHive.openBox<Node>(Node.boxName);
    sharedPreferences = await SharedPreferences.getInstance();
  }

  /// Get all trusted nodes for a specific wallet type
  List<Node> getTrustedNodes(WalletType walletType) {
    return nodeSource.values.where((node) => node.type == walletType).toList();
  }

  Node? getCurrentNode(WalletType walletType) {
    final nodeId = _getCurrentNodeId(walletType);
    if (nodeId != null) {
      return nodeSource.get(nodeId);
    }
    return null;
  }

  /// Get the next available trusted node for a wallet type
  /// Cycles through nodes in order and tracks used nodes to avoid repetition
  Node? getNextTrustedNode(WalletType walletType, {Node? excludeNode}) {
    final trustedNodes = getTrustedNodes(walletType);

    if (trustedNodes.isEmpty) {
      log('No trusted nodes available for wallet type: $walletType');
      return null;
    }

    // Get or create the used nodes set for this wallet type
    final usedNodeIds = _usedNodeIds.putIfAbsent(walletType, () => <int>{});

    // If we have a node to exclude, add it to the used nodes set
    if (excludeNode != null) {
      usedNodeIds.add(excludeNode.key as int);
      log('Added node ${excludeNode.key} to used nodes for $walletType. Total used: ${usedNodeIds.length}');
    }

    // Filter out used nodes to get available nodes
    final availableNodes = trustedNodes.where((node) => !usedNodeIds.contains(node.key)).toList();

    // If all nodes have been used, reset the used nodes set and start over
    if (availableNodes.isEmpty) {
      log('All trusted nodes have been used for $walletType, resetting used nodes list');
      usedNodeIds.clear();
      return trustedNodes.first;
    }

    // Return the first available node (maintains order from the original list)
    final selectedNode = availableNodes.first;
    log('Selected next node: ${selectedNode.uriRaw} for $walletType. Available: ${availableNodes.length}/${trustedNodes.length}');
    return selectedNode;
  }

  /// Switch to the next available trusted node
  Future<bool> switchToNextNode(WalletType walletType, {Node? excludeNode}) async {
    final nextNode = getNextTrustedNode(walletType, excludeNode: excludeNode);

    if (nextNode == null) {
      log('No next node available for wallet type: $walletType');
      return false;
    }

    try {
      await _setCurrentNode(walletType, nextNode);
      log('Successfully switched to next node: ${nextNode.uriRaw} for wallet type: $walletType');
      return true;
    } catch (e) {
      log('Failed to switch to next node: $e');
      return false;
    }
  }

  /// Check if automatic node switching is enabled
  bool isAutomaticNodeSwitchingEnabled() {
    return sharedPreferences.getBool('automatic_node_switching_enabled') ?? true;
  }

  /// Enable or disable automatic node switching
  Future<void> setAutomaticNodeSwitchingEnabled(bool enabled) async {
    await sharedPreferences.setBool('automatic_node_switching_enabled', enabled);
  }

  /// Get the current node ID for a wallet type
  int? _getCurrentNodeId(WalletType walletType) {
    switch (walletType) {
      case WalletType.monero:
        return sharedPreferences.getInt('current_node_id');
      case WalletType.bitcoin:
        return sharedPreferences.getInt('current_node_id_btc');
      case WalletType.litecoin:
        return sharedPreferences.getInt('current_node_id_ltc');
      case WalletType.ethereum:
        return sharedPreferences.getInt('current_node_id_eth');
      case WalletType.polygon:
        return sharedPreferences.getInt('current_node_id_matic');
      case WalletType.nano:
        return sharedPreferences.getInt('current_node_id_nano');
      case WalletType.solana:
        return sharedPreferences.getInt('current_node_id_sol');
      case WalletType.tron:
        return sharedPreferences.getInt('current_node_id_trx');
      case WalletType.wownero:
        return sharedPreferences.getInt('current_node_id_wow');
      case WalletType.zano:
        return sharedPreferences.getInt('current_node_id_zano');
      case WalletType.decred:
        return sharedPreferences.getInt('current_node_id_decred');
      case WalletType.bitcoinCash:
        return sharedPreferences.getInt('current_node_id_bch');
      case WalletType.haven:
        return sharedPreferences.getInt('current_node_id_xhv');
      case WalletType.banano:
        return sharedPreferences.getInt('current_node_id_banano');
      case WalletType.none:
        return null;
    }
  }

  /// Set the current node for a wallet type
  Future<void> _setCurrentNode(WalletType walletType, Node node) async {
    switch (walletType) {
      case WalletType.monero:
        await sharedPreferences.setInt('current_node_id', node.key as int);
        break;
      case WalletType.bitcoin:
        await sharedPreferences.setInt('current_node_id_btc', node.key as int);
        break;
      case WalletType.litecoin:
        await sharedPreferences.setInt('current_node_id_ltc', node.key as int);
        break;
      case WalletType.ethereum:
        await sharedPreferences.setInt('current_node_id_eth', node.key as int);
        break;
      case WalletType.polygon:
        await sharedPreferences.setInt('current_node_id_matic', node.key as int);
        break;
      case WalletType.nano:
        await sharedPreferences.setInt('current_node_id_nano', node.key as int);
        break;
      case WalletType.solana:
        await sharedPreferences.setInt('current_node_id_sol', node.key as int);
        break;
      case WalletType.tron:
        await sharedPreferences.setInt('current_node_id_trx', node.key as int);
        break;
      case WalletType.wownero:
        await sharedPreferences.setInt('current_node_id_wow', node.key as int);
        break;
      case WalletType.zano:
        await sharedPreferences.setInt('current_node_id_zano', node.key as int);
        break;
      case WalletType.decred:
        await sharedPreferences.setInt('current_node_id_decred', node.key as int);
        break;
      case WalletType.bitcoinCash:
        await sharedPreferences.setInt('current_node_id_bch', node.key as int);
        break;
      case WalletType.haven:
        await sharedPreferences.setInt('current_node_id_xhv', node.key as int);
        break;
      case WalletType.banano:
        await sharedPreferences.setInt('current_node_id_banano', node.key as int);
        break;
      case WalletType.none:
        break;
    }
  }
}
