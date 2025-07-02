import 'dart:async';
import 'package:cw_core/node.dart';
import 'package:cw_core/node_switching_service.dart';
import 'package:cw_core/wallet_type.dart';

class NodeSwitchingConfig {
  const NodeSwitchingConfig({
    this.maxRetriesPerNode = 3,
    this.maxNodeSwitches = 2,
    this.retryDelay = const Duration(milliseconds: 500),
  });

  /// Maximum number of retries per node before switching
  final int maxRetriesPerNode;

  /// Maximum number of node switches to attempt
  final int maxNodeSwitches;

  /// Delay between retries
  final Duration retryDelay;
}

mixin NodeSwitchingMixin {
  NodeSwitchingService? get nodeSwitchingService => NodeSwitchingService.instance;

  Node? _currentNode;

  // Mutex for preventing concurrent node switches
  final _nodeSwitchMutex = _SimpleMutex();

  // Track active operations to prevent switching during active calls
  final Set<Completer<void>> _activeOperations = {};

  /// Set the current node for this client
  void setCurrentNode(Node node) {
    _currentNode = node;
  }

  /// Get the current node for this client
  Node? get currentNode => _currentNode;

  /// Execute an RPC call with intelligent retry and node switching
  ///
  /// The execution flow:
  /// 1. Attempt the RPC call on the current node
  /// 2. If it fails, retry with fixed delay up to `maxRetriesPerNode` times
  /// 3. If all retries fail, switch to the next available trusted node
  /// 4. Repeat the process for up to `maxNodeSwitches` different nodes
  /// 5. If all attempts fail, throw a descriptive exception
  Future<T> executeWithNodeSwitching<T>(
    Future<T> Function() rpcCall,
    WalletType walletType, {
    NodeSwitchingConfig config = const NodeSwitchingConfig(),
    String? methodName,
    required Future<bool> Function(Node node) connectCallback,
  }) async {
    final state = _NodeSwitchingState(
      walletType: walletType,
      config: config,
      methodName: methodName,
      currentNode: _currentNode,
    );

    // Track this operation
    final operationCompleter = Completer<void>();
    _activeOperations.add(operationCompleter);

    try {
      for (int nodeSwitchCount = 0; nodeSwitchCount <= config.maxNodeSwitches; nodeSwitchCount++) {
        final result = await _attemptOnCurrentNode(rpcCall, state, connectCallback);
        if (result != null) {
          return result;
        }

        // If we haven't reached max node switches, try switching to next node
        if (nodeSwitchCount < config.maxNodeSwitches) {
          final switched = await _switchToNextNode(state, connectCallback);
          if (!switched) {
            break; // No more nodes available
          }
        }
      }

      throw _createFailureException(state);
    } finally {
      // Remove this operation from tracking
      _activeOperations.remove(operationCompleter);
      operationCompleter.complete();
    }
  }

  /// Attempt to execute the RPC call on the current node with retries
  Future<T?> _attemptOnCurrentNode<T>(
    Future<T> Function() rpcCall,
    _NodeSwitchingState state,
    Future<bool> Function(Node node) connectCallback,
  ) async {
    if (state.currentNode == null) {
      final serviceNode = nodeSwitchingService?.getCurrentNode(state.walletType);
      if (serviceNode != null) {
        state.currentNode = serviceNode;
        setCurrentNode(serviceNode);
      } else {
        return null;
      }
    }

    for (int retryCount = 0; retryCount <= state.config.maxRetriesPerNode; retryCount++) {
      try {
        final result = await rpcCall();
        return result;
      } catch (e) {
        final isLastRetry = retryCount == state.config.maxRetriesPerNode;
        if (isLastRetry) {
          break;
        }

        await Future.delayed(state.config.retryDelay);
      }
    }

    return null;
  }

  /// Switch to the next available node
  Future<bool> _switchToNextNode(
    _NodeSwitchingState state,
    Future<bool> Function(Node node) connectCallback,
  ) async {
    if (!_canSwitchNodes(state)) {
      return false;
    }

    // Use mutex to prevent concurrent node switches
    return await _nodeSwitchMutex.acquire(() async {
      // Wait for any active operations to complete
      if (_activeOperations.isNotEmpty) {
        await Future.wait(_activeOperations.map((op) => op.future));
      }

      final service = nodeSwitchingService;
      if (service == null) {
        return false;
      }

      final switched = await service.switchToNextNode(
        state.walletType,
        excludeNode: state.currentNode,
      );

      if (!switched) {
        return false;
      }

      final nextNode = service.getCurrentNode(state.walletType);
      if (nextNode == null) {
        return false;
      }

      final connected = await connectCallback(nextNode);

      if (connected) {
        setCurrentNode(nextNode);
        state.currentNode = nextNode;
        return true;
      } else {
        return false;
      }
    });
  }

  /// Check if node switching is possible and enabled
  bool _canSwitchNodes(_NodeSwitchingState state) {
    if (nodeSwitchingService == null) {
      return false;
    }

    if (state.currentNode == null) {
      return false;
    }

    if (!nodeSwitchingService!.isAutomaticNodeSwitchingEnabled()) {
      return false;
    }

    return true;
  }

  /// Create a descriptive failure exception
  Exception _createFailureException(_NodeSwitchingState state) {
    final nodeInfo = state.currentNode?.uriRaw ?? 'unknown';
    final methodInfo = state.methodName ?? 'unknown';

    return Exception(
      'RPC call failed after ${state.config.maxRetriesPerNode + 1} retries per node '
      'across ${state.config.maxNodeSwitches + 1} nodes. '
      'Last attempted node: $nodeInfo. '
      'Method: $methodInfo. '
      'Wallet type: ${state.walletType}',
    );
  }
}

/// Internal state class to hold state during node switching
class _NodeSwitchingState {
  _NodeSwitchingState({
    required this.walletType,
    required this.config,
    this.methodName,
    Node? currentNode,
  }) : currentNode = currentNode;

  final WalletType walletType;
  final NodeSwitchingConfig config;
  final String? methodName;
  Node? currentNode;
}

/// Simple mutex implementation for preventing concurrent node switches
class _SimpleMutex {
  Completer<void>? _lock;

  Future<T> acquire<T>(Future<T> Function() criticalSection) async {
    // Wait for any existing lock to be released
    while (_lock != null) {
      await _lock!.future;
    }

    // Create new lock
    _lock = Completer<void>();

    try {
      return await criticalSection();
    } finally {
      // Release lock
      _lock!.complete();
      _lock = null;
    }
  }
}
