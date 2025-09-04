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

  // Maximum number of node attempts before giving up
  // This prevents endless switching for users with slow network connections
  static const int _maxNodeAttempts = 5;

  // State to manage the attempt count
  int _attemptCount = 0;

  String walletName = '';

  Timer? _healthCheckTimer;

  bool _isSwitching = false;
  bool get isSwitching => _isSwitching;

  // Track if we've exhausted all node attempts for the current session
  bool _hasExhaustedNodeAttempts = false;

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

    // Reset attempt count when wallet changes
    if (walletName.isNotEmpty && (walletName != appStore.wallet!.name)) {
      _resetAttemptCount();
    }

    // Don't perform health checks if we've exhausted all node attempts
    if (_hasExhaustedNodeAttempts) {
      printV('Node attempts exhausted, skipping health check');
      return;
    }

    try {
      // Add timeout to prevent hanging on slow network connections
      final isHealthy = await appStore.wallet!.checkNodeHealth()
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              printV('Health check timed out, considering node unhealthy');
              return false;
            },
          );

      if (!isHealthy) {
        await _switchToNextTrustedNode();
      }
    } catch (e) {
      printV('Error during health check: $e');
    }
  }

  /// Reset the attempt count and exhaustion state
  void _resetAttemptCount() {
    _attemptCount = 0;
    _hasExhaustedNodeAttempts = false;
    _usedNodeKeys.clear();
    printV('Reset node attempt count for wallet: ${appStore.wallet!.name}');
  }

  /// Switch to the next available trusted node
  Future<void> _switchToNextTrustedNode() async {
    _isSwitching = true;

    if (walletName.isNotEmpty && (walletName != appStore.wallet!.name)) {
      _resetAttemptCount();
    }

    walletName = appStore.wallet!.name;

    // Check if we've reached the maximum number of attempts
    if (_attemptCount >= _maxNodeAttempts) {
      printV('Maximum node attempts ($_maxNodeAttempts) reached, stopping node switching');
      _hasExhaustedNodeAttempts = true;
      _isSwitching = false;
      return;
    }

    _attemptCount++;

    try {
      final walletType = appStore.wallet!.type;
      final currentNode = settingsStore.getCurrentNode(walletType);

      // Get all trusted nodes for this wallet type
      final trustedNodes = nodeSource.values
          .where((node) => node.type == walletType && node.isEnabledForAutoSwitching)
          .toList();

      if (trustedNodes.isEmpty) {
        printV('No trusted nodes available for switching');
        _hasExhaustedNodeAttempts = true;
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

      // If all trusted nodes have been used, we've exhausted our options
      if (nextNode == null) {
        printV('All trusted nodes have been tried, stopping node switching');
        _hasExhaustedNodeAttempts = true;
        return;
      }

      // Add the next node to used list
      _usedNodeKeys[walletType]!.add(nextNode.key);

      printV('Switching from ${currentNode.uriRaw} to ${nextNode.uriRaw} (attempt $_attemptCount/$_maxNodeAttempts)');
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
