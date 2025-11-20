import 'dart:async';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cake_wallet/evm/evm.dart';

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
  static const int _nodeSwitchingCooldownSeconds = 15;

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

  /// Find an active node from the provided list, checking only unused nodes
  /// Marks inactive nodes as used to avoid retrying them
  Future<Node?> _findActiveNode(
    List<Node> nodes,
    WalletType walletType,
  ) async {
    for (final node in nodes) {
      if (!_usedNodeKeys[walletType]!.contains(node.key)) {
        final isActive = await node.requestNode();
        if (isActive) {
          return node;
        } else {
          printV('Node ${node.uriRaw} is not active. Marking as used.');
          _usedNodeKeys[walletType]!.add(node.key);
        }
      }
    }
    return null;
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

      final wallet = appStore.wallet!;
      final walletType = wallet.type;
      
      int? chainId;
      WalletType nodeWalletType = walletType;
      
      if (walletType == WalletType.evm) {
        chainId = evm!.getSelectedChainId(wallet);
        if (chainId != null) {
          final chainWalletType = evm!.getWalletTypeByChainId(chainId);
          if (chainWalletType != null) {
            nodeWalletType = chainWalletType;
          }
        }
      }
      
      final currentNode = settingsStore.getCurrentNode(walletType, chainId: chainId);

      // Get all trusted nodes for this wallet type
      // For WalletType.evm, filter by the chain-specific wallet type
      final trustedNodes = nodeSource.values
          .where((node) => node.type == nodeWalletType && node.isEnabledForAutoSwitching)
          .toList();

      if (trustedNodes.isEmpty) {
        printV('No trusted nodes available for switching');
        _hasExhaustedAllNodes = true;
        return;
      }

      // Initialize used nodes list for this wallet type if it does not exist
      _usedNodeKeys.putIfAbsent(nodeWalletType, () => []);

      // Add current node to used list if not already there
      if (!_usedNodeKeys[nodeWalletType]!.contains(currentNode.key)) {
        _usedNodeKeys[nodeWalletType]!.add(currentNode.key);
      }

      // Try to find an active unused node
      Node? nextNode = await _findActiveNode(trustedNodes, nodeWalletType);

      // If all trusted nodes have been used, check if we should reset
      if (nextNode == null) {
        printV('All trusted nodes have been tried for wallet type: $nodeWalletType');

        // If we've tried all nodes and still haven't reached max attempts, reset and try again
        if (_switchingAttempts < _maxNodeSwitchingAttempts) {
          printV('Resetting used nodes list and trying again');
          _usedNodeKeys[nodeWalletType]!.clear();
          // Try again with cleared used list
          nextNode = await _findActiveNode(trustedNodes, nodeWalletType);
        }

        // If still no active node found, we give up
        if (nextNode == null) {
          printV('No active nodes available for switching after checking all nodes.');
          _hasExhaustedAllNodes = true;
          return;
        }
      }

      // Ensure the selected node is marked as used
      if (!_usedNodeKeys[nodeWalletType]!.contains(nextNode.key)) {
        _usedNodeKeys[nodeWalletType]!.add(nextNode.key);
      }

      printV(
          'Switching from ${currentNode.uriRaw} to ${nextNode.uriRaw} (attempt $_switchingAttempts/$_maxNodeSwitchingAttempts)');
      printV('Used nodes for ${nodeWalletType}: ${_usedNodeKeys[nodeWalletType]}');

      // Update the current node in settings
      settingsStore.nodes[walletType] = nextNode;

      // Connect the wallet to the new node
      await appStore.wallet!.connectToNode(node: nextNode);

      await appStore.wallet!.startSync();

      printV('Successfully switched to node: ${nextNode.uriRaw}');
    } catch (e) {
      printV('Error switching to next trusted node: $e');
    } finally {
      // Increment switching attempts counter on every attempt
      _switchingAttempts++;
      _lastSwitchingAttempt = DateTime.now();
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
