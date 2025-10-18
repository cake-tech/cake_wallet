import 'dart:async';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NodeSwitchingService {
  NodeSwitchingService({
    required this.appStore,
    required this.settingsStore,
    required this.nodeSource,
  });

  static const int _healthCheckIntervalSeconds = 30;

  // Maximum number of node switching attempts per session
  static const int _maxNodeSwitchingAttempts = 5;

  // Cooldown period between node switching attempts (in seconds)
  static const int _nodeSwitchingCooldownSeconds = 60;

  // State to manage switching attempts and cooldown
  int _switchingAttempts = 0;
  DateTime? _lastSwitchingAttempt;
  bool _hasExhaustedAllNodes = false;

  String walletName = '';

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

    // Reset counters when wallet changes
    if (walletName.isNotEmpty && walletName != appStore.wallet!.name) {
      _resetSwitchingState();
    }
    walletName = appStore.wallet!.name;

    // Check if we've exhausted all switching attempts
    if (_hasExhaustedAllNodes) {
      printV('Node switching exhausted for wallet: $walletName. Skipping health check.');
      return;
    }

    // Check cooldown period
    if (_lastSwitchingAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastSwitchingAttempt!);
      if (timeSinceLastAttempt.inSeconds < _nodeSwitchingCooldownSeconds) {
        printV('Node switching in cooldown period. Skipping health check.');
        return;
      }
    }

    try {
      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        printV('No network connectivity detected. Skipping node health check.');
        return;
      }

      final isHealthy = await appStore.wallet!.checkNodeHealth();

      if (!isHealthy) {
        printV('Node health check failed. Attempting to switch to next trusted node.');
        await _switchToNextTrustedNode();
      } else {
        // Reset switching attempts on successful health check
        _switchingAttempts = 0;
        _hasExhaustedAllNodes = false;
        printV('Node health check passed. Current node is healthy.');
      }
    } catch (e) {
      printV('Error during health check: $e');
    }
  }

  /// Switch to the next available trusted node
  Future<void> _switchToNextTrustedNode() async {
    _isSwitching = true;

    try {
      // Check if we've exceeded maximum switching attempts
      if (_switchingAttempts >= _maxNodeSwitchingAttempts) {
        printV('Maximum node switching attempts ($_maxNodeSwitchingAttempts) reached. '
            'Disabling automatic switching.');
        _hasExhaustedAllNodes = true;
        return;
      }

      final walletType = appStore.wallet!.type;
      final currentNode = settingsStore.getCurrentNode(walletType);

      // Get all trusted nodes for this wallet type
      final trustedNodes = nodeSource.values
          .where((node) => node.type == walletType && node.isEnabledForAutoSwitching)
          .toList();

      if (trustedNodes.isEmpty) {
        printV('No trusted nodes available for switching');
        _hasExhaustedAllNodes = true;
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

      // If all trusted nodes have been used, check if we should reset
      if (nextNode == null) {
        printV('All trusted nodes have been tried for wallet type: $walletType');

        // If we've tried all nodes and still haven't reached max attempts, reset and try again
        if (_switchingAttempts < _maxNodeSwitchingAttempts) {
          printV('Resetting used nodes list and trying again');
          _usedNodeKeys[walletType]!.clear();
          nextNode = trustedNodes.first;
        } else {
          printV('Maximum attempts reached. No more node switching.');
          _hasExhaustedAllNodes = true;
          return;
        }
      }

      // Increment switching attempts counter
      _switchingAttempts++;
      _lastSwitchingAttempt = DateTime.now();

      // Add the next node to used list
      _usedNodeKeys[walletType]!.add(nextNode.key);

      printV(
          'Switching from ${currentNode.uriRaw} to ${nextNode.uriRaw} (attempt $_switchingAttempts/$_maxNodeSwitchingAttempts)');
      printV('Used nodes for ${walletType}: ${_usedNodeKeys[walletType]}');

      // Update the current node in settings
      settingsStore.nodes[walletType] = nextNode;

      // Connect the wallet to the new node
      await appStore.wallet!.connectToNode(node: nextNode);

      await appStore.wallet!.startSync();

      printV('Successfully switched to node: ${nextNode.uriRaw}');
    } catch (e) {
      printV('Error switching to next trusted node: $e');

      // Increment attempts even on error to prevent infinite retries
      _switchingAttempts++;
      _lastSwitchingAttempt = DateTime.now();
    } finally {
      _isSwitching = false;
    }
  }

  /// Reset switching state when wallet changes
  void _resetSwitchingState() {
    _switchingAttempts = 0;
    _lastSwitchingAttempt = null;
    _hasExhaustedAllNodes = false;
    _usedNodeKeys.clear();
    printV('Node switching state reset for new wallet');
  }

  /// Check if automatic node switching is currently disabled due to exhaustion
  bool get isAutomaticSwitchingDisabled => _hasExhaustedAllNodes;
}
