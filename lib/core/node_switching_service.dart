import 'dart:async';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';

class NodeSwitchingService {
  NodeSwitchingService({
    required this.appStore,
    required this.settingsStore,
    required this.nodeSource,
  });

  static const int _healthCheckIntervalSeconds = 30;

  // The number of times we want to reset the overall used trusted nodes list. 
  // We don't want an infinite loop if all trusted nodes are down.
  static const int _usedTrustedNodeResetCount = 2;

  // State to manage the reset count
  int _resetCount = 0;

  Timer? _healthCheckTimer;

  bool _isSwitching = false;
  bool get isSwitching => _isSwitching;

  final AppStore appStore;
  final SettingsStore settingsStore;
  final Box<Node> nodeSource;

  // Track used nodes to cycle through all trusted nodes
  final Map<WalletType, List<dynamic>> _usedNodeKeys = {};

  void startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      Duration(seconds: _healthCheckIntervalSeconds),
      (_) => performHealthCheck(),
    );

    performHealthCheck();
  }

  void stopHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  Future<void> performHealthCheck() async {
    if (appStore.wallet == null) return;

    if (!settingsStore.enableAutomaticNodeSwitching) return;

    if (_isSwitching) return;

    try {
      final isHealthy = await appStore.wallet!.checkNodeHealth();

      if (!isHealthy) {
        await _switchToNextTrustedNode();
      }
    } catch (e) {
      printV('Error during health check: $e');
    }
  }

  /// Switch to the next available trusted node
  Future<void> _switchToNextTrustedNode() async {
    _isSwitching = true;

    try {
      final walletType = appStore.wallet!.type;
      final currentNode = settingsStore.getCurrentNode(walletType);

      // Get all trusted nodes for this wallet type
      final trustedNodes = nodeSource.values
          .where((node) => node.type == walletType && node.isEnabledForAutoSwitching)
          .toList();

      if (trustedNodes.isEmpty) {
        printV('No trusted nodes available for switching');
        return;
      }

      // Initialize used nodes list for this wallet type if it does not exist
      _usedNodeKeys.putIfAbsent(walletType, () => []);

      // Add current node to used list if not already there
      if (!_usedNodeKeys[walletType]!.contains(currentNode.key)) {
        _usedNodeKeys[walletType]!.add(currentNode.key);
      }

      // Get next unused trusted node from the list
      Node? nextNode;
      for (final node in trustedNodes) {
        if (!_usedNodeKeys[walletType]!.contains(node.key)) {
          nextNode = node;
          break;
        }
      }

      // If all trusted nodes have been used, reset the list and start over
      if (nextNode == null) {
        printV('All trusted nodes have been tried, resetting and starting over');
        _resetCount++;

        if (_resetCount > _usedTrustedNodeResetCount) return;

        _usedNodeKeys[walletType]!.clear();
        nextNode = trustedNodes.first;
      }

      // Add the next node to used list
      _usedNodeKeys[walletType]!.add(nextNode.key);

      printV('Switching from ${currentNode.uriRaw} to ${nextNode.uriRaw}');
      printV('Used nodes for ${walletType}: ${_usedNodeKeys[walletType]}');

      // Update the current node in settings
      settingsStore.nodes[walletType] = nextNode;

      // Connect the wallet to the new node
      await appStore.wallet!.connectToNode(node: nextNode);

      await appStore.wallet!.startSync();

      printV('Successfully switched to node: ${nextNode.uriRaw}');
    } catch (e) {
      printV('Error switching to next trusted node: $e');
    } finally {
      _isSwitching = false;
    }
  }
}
