import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum ConnectionStatus { connected, disconnected, connecting, failed }

String jsonrpcparams(List<Object> params) {
  final _params = params.map((val) => '"${val.toString()}"').join(',');
  return '[$_params]';
}

String jsonrpc(
        {required String method,
        required List<Object> params,
        required int id,
        double version = 2.0}) =>
    '{"jsonrpc": "$version", "method": "$method", "id": "$id",  "params": ${json.encode(params)}}\n';

class SocketTask {
  SocketTask({required this.isSubscription, this.completer, this.subject});

  final Completer<dynamic>? completer;
  final BehaviorSubject<dynamic>? subject;
  final bool isSubscription;
}

class ElectrumClient {
  ElectrumClient()
      : _id = 0,
        _tasks = {},
        _errors = {},
        unterminatedString = '';

  static const connectionTimeout = Duration(seconds: 5);
  static const aliveTimerDuration = Duration(seconds: 5);

  // ── Request metrics ──────────────────────────────────────────────────────────
  int _requestCount = 0;
  int _requestsThisConnection = 0;
  DateTime? _connectionEstablishedAt;
  DateTime? _disconnectedAt;
  final List<DateTime> _recentRequestTimestamps = [];
  // ─────────────────────────────────────────────────────────────────────────────

  // ── Reconnection backoff ─────────────────────────────────────────────────────
  static const _backoffBase = Duration(seconds: 5);
  static const _maxBackoff = Duration(seconds: 60);
  int _consecutiveFailures = 0;
  // ─────────────────────────────────────────────────────────────────────────────

  // ── Batching ─────────────────────────────────────────────────────────────────

  String serverVersion = '';

  Future<dynamic> getHistoryData(List<String> scriptHashes) async {
    batchGetData(scriptHashes, 'blockchain.scripthash.get_history');
    for (var i = 0; i < scriptHashes.length; i++) {
      final sh = scriptHashes[i];
      printV('getHistoryData: Requested history for scripthash $sh');
    }
  }

  Future<dynamic> getBatchResults(String batch) async {
    if (batch.isEmpty) {
      return {};
    }
    if (!isConnected) {
      throw Exception('Not connected to Electrum server');
    }
    try {
      final completer = Completer<dynamic>();
      final requestId = _id;
      _registryTask(requestId, completer);
      socket!.write(batch + '\n');
      
      final response = await completer.future.timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Batch request timed out after 60 seconds');
        },
      );
      printV("Do we have a response for batch request? ${response != null}");
      return response;
    } catch (e) {
      printV("Error preparing batch request: $e");
      rethrow;
    }

    
  }
      

  Future<dynamic> batchGetData(List<String> scriptHashes, String method) async {
    // throw UnimplementedError("Deprecated");
    if (scriptHashes.isEmpty) {
      return {};
    }

    try {
      // OPTIMIZATION: Split into batches of max 50 operations
      const int maxBatchSize = 50;
      final List<dynamic> allResults = [];
      
      // We're not going to loop the whole dataset here
      // Loop the data in the invoking function so we can save results even when future batches fail
      for (int batchStart = 0; batchStart < scriptHashes.length; batchStart += maxBatchSize) {
        final batchEnd = (batchStart + maxBatchSize < scriptHashes.length) 
            ? batchStart + maxBatchSize 
            : scriptHashes.length;
        final batchScriptHashes = scriptHashes.sublist(batchStart, batchEnd);
        
        // Build batch request payload for this chunk
        final List<Map<String, dynamic>> batchRequest = [];
        final int batchStartId = 0;
        final int batchEndId = batchScriptHashes.length - 1;
        _id++;
        final int batchBaseId = _id; // Base ID for this batch
        final String batchId = 'batch_${batchStartId}_${batchEndId}_${batchBaseId}';
        // We already incremented _id - so it is in sync 
        
        
        for (int i = 0; i < batchScriptHashes.length; i++) {
          batchRequest.add({
            'jsonrpc': '2.0',
            'id': 'batch_${batchStartId}_${_id}',
            'method': method,
            'params': [batchScriptHashes[i]],
          });
        }

        final batchRequestJson = json.encode(batchRequest);
        printV('batchGetData: Sending batch ${batchStart ~/ maxBatchSize + 1} of ${(scriptHashes.length / maxBatchSize).ceil()} (${batchScriptHashes.length} operations)');

        // Send batch request
        if (!isConnected) {
          throw Exception('Not connected to Electrum server');
        }

        // Use a special string ID for batch requests to avoid conflicts
        final completer = Completer<dynamic>();
        //final batchId = 'batch_${batchStartId}_${_id}';
        printV('batchId: $batchId');
        _tasks[batchId] = SocketTask(completer: completer, isSubscription: false);

        // Write the batch request directly to socket
        socket!.write(batchRequestJson + '\n');
        printV('batchGetData: Batch request sent with ID range: $batchStartId-$_id (batch key: $batchId)');

        final response = await completer.future.timeout(
          Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Batch request timed out after 60 seconds');
          },
        );
        
        if (response is List<dynamic>) {
          allResults.addAll(response);
        }
        
        // OPTIMIZATION: 100ms delay between batches to allow server processing time
        // This prevents overwhelming Fulcrum's request queue and gives it time to query bitcoind
        if (batchEnd < scriptHashes.length) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      // Sort all results by id field to maintain deterministic ordering
      // Outside of non-key-value maps, we want to order transactions correctly
      // The invoking function is expected to implement matching for results to script hashes too, not just for numbered lists
      allResults.sort((a, b) {
        if (a is Map<String, dynamic> && b is Map<String, dynamic>) {
          final aId = a['id'] as int? ?? 0;
          final bId = b['id'] as int? ?? 0;
          return aId.compareTo(bId);
        }
        return 0;
      });

      return allResults;
    } catch (e) {
      printV('batchGetResponse error: $e');
      return {};
    }
  }

  bool get isConnected => socket != null && socket?.isClosed == false;
  ProxySocket? socket;
  void Function(ConnectionStatus)? onConnectionStatusChange;
  int _id;
  final Map<String, SocketTask> _tasks;
  Map<String, SocketTask> get tasks => _tasks;
  final Map<String, String> _errors;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Timer? _aliveTimer;
  String unterminatedString;

  Uri? uri;
  bool? useSSL;

  Future<void> connectToUri(Uri uri, {bool? useSSL}) async {
    this.uri = uri;
    if (useSSL != null) {
      this.useSSL = useSSL;
    }
    await connect(host: uri.host, port: uri.port);
  }

  Future<void> connect({required String host, required int port}) async {
    _setConnectionStatus(ConnectionStatus.connecting);

    // Reset internal state to ensure clean connection
    _resetInternalState();

    try {
      await socket?.close();
    } catch (_) {}
    socket = null;

    final ssl = !(useSSL == false || (useSSL == null && uri.toString().contains("btc-electrum")));
    try {
      socket = await ProxyWrapper()
          .getSocksSocket(ssl, host, port, connectionTimeout: connectionTimeout);
    } catch (e) {
      printV("connect: $e");
      if (e is HandshakeException) {
        useSSL = !(useSSL ?? false);
      }

      if (_connectionStatus != ConnectionStatus.connecting) {
        _setConnectionStatus(ConnectionStatus.failed);
      }

      return;
    }

    if (socket == null) {
      if (_connectionStatus != ConnectionStatus.connecting) {
        _setConnectionStatus(ConnectionStatus.failed);
      }

      return;
    }

    // use ping to determine actual connection status since we could've just not timed out yet:
    // _setConnectionStatus(ConnectionStatus.connected);
    socket!.listen(
      (Uint8List event) {
        try {
          final msg = utf8.decode(event.toList());
          final messagesList = msg.split("\n");
          for (var message in messagesList) {
            // For some reason, some servers will serve us garbage whitespace characters
            // Skip empty messages or messages with only whitespace/control chars
            message = message.trim();
            if (message.isEmpty || message.replaceAll(RegExp(r'[\s\x00-\x1F\x7F]'), '').isEmpty) {
              continue;
            }
            printV("Received message: $message");
            _parseResponse(message);
          }
        } catch (e) {
          printV("socket.listen: $e");
        }
      },
      onError: (Object error) {
        final errorMsg = error.toString();
        printV(errorMsg);
        unterminatedString = '';
        socket?.destroy();
        socket = null;
        _setConnectionStatus(ConnectionStatus.disconnected);
      },
      onDone: () {
        printV("SOCKET CLOSED!!!!!");
        printV("The socket ID was ${_id}");
        unterminatedString = '';
        try {
          _setConnectionStatus(ConnectionStatus.disconnected);
          socket?.destroy();
          socket = null;
        } catch (e) {
          printV("onDone: $e");
        }
      },
      cancelOnError: true,
    );

    keepAlive();
  }


      // Check for single response (object) or batch response
  void _parseResponse(String message) {
    try {
      final decoded = json.decode(message);
      // Handle batch response (list) or single response (object)
      if (decoded is List) {
        // Handle batch response - find matching batch task by ID range
        printV("Received batch response with ${decoded.length} items");
        
        if (decoded.isEmpty) {
          printV('Warning: Received empty batch response');
          return;
        }
        
        // Extract ID range from batch response
        final ids = decoded
            .where((item) => item is Map<String, dynamic> && item['id'] != null)
            .map((item) => item['id'] as int)
            .toList();
        
        if (ids.isEmpty) {
          printV('Warning: Batch response has no valid IDs');
          return;
        }
        
        ids.sort();
        final minId = ids.first;
        final maxId = ids.last;
        final batchId = 'batch_${minId}_${maxId}';
        
        printV('Looking for batch task with key: $batchId');
        
        // Find and complete the matching batch task
        final task = _tasks[batchId];
        if (task != null && !task.isSubscription && task.completer != null && !task.completer!.isCompleted) {
          task.completer!.complete(decoded);
          _tasks.remove(batchId);
          printV('Completed batch request $batchId with ${decoded.length} results');
        } else {
          printV('Warning: No matching batch task found for $batchId. Available tasks: ${_tasks.keys.where((k) => k.startsWith("batch_")).toList()}');
        }
      } else if (decoded is Map<String, dynamic>) {
        // Handle single response
        printV("Received response for message ID: ${decoded['id']} with method: ${decoded['method']}");
        _handleResponse(decoded);
      }
    } on FormatException catch (e) {
      final msg = e.message.toLowerCase();

      if (e.source is String) {
        unterminatedString += e.source as String;
      }

      if (msg.contains("not a subtype of type")) {
        unterminatedString += e.source as String;
        return;
      }

      if (isJSONStringCorrect(unterminatedString)) {
        final response = json.decode(unterminatedString) as Map<String, dynamic>;
        _handleResponse(response);
        unterminatedString = '';
      }
    } on TypeError catch (e) {
      if (!e.toString().contains('Map<String, Object>') &&
          !e.toString().contains('Map<String, dynamic>')) {
        return;
      }

      unterminatedString += message;

      if (isJSONStringCorrect(unterminatedString)) {
        final response = json.decode(unterminatedString) as Map<String, dynamic>;
        _handleResponse(response);
        // unterminatedString = null;
        unterminatedString = '';
      }
    } catch (e) {
      printV("parse $e");
    }
  }

  void keepAlive() {
    _aliveTimer?.cancel();
    _aliveTimer = Timer.periodic(aliveTimerDuration, (_) async => ping());
  }

  Future<void> ping() async {
    try {
      await callWithTimeout(method: 'server.ping');
      _setConnectionStatus(ConnectionStatus.connected);
    } catch (_) {
      _setConnectionStatus(ConnectionStatus.disconnected);
    }
  }

  /// Calculate next reconnection delay using linear backoff
  /// Formula: base_delay * (failures + 1), capped at max_backoff
  /// Examples: 5s, 10s, 15s, 20s, ... up to 60s
  Duration getReconnectionDelay() {
    final delay = _backoffBase * (_consecutiveFailures + 1);
    return delay > _maxBackoff ? _maxBackoff : delay;
  }

  Future<List<String>> version() =>
      call(method: 'server.version', params: ["", "1.4"]).then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) => val.toString()).toList();
        }

        return [];
      });

  Future<Map<String, dynamic>> getBalance(String scriptHash, {bool throwOnError = false}) async {
    try {
      final result = await call(method: 'blockchain.scripthash.get_balance', params: [scriptHash]);
      if (result is Map<String, dynamic>) {
        return result;
      }

      if (throwOnError) {
        throw Exception('Invalid response format for getBalance');
      }

      return <String, dynamic>{};
    } catch (e) {
      if (throwOnError) {
        rethrow;
      }
      return <String, dynamic>{};
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(String scriptHash) =>
      call(method: 'blockchain.scripthash.get_history', params: [scriptHash])
          .then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, dynamic>) {
              return val;
            }

            return <String, dynamic>{};
          }).toList();
        }

        return [];
      });

  Future<List<Map<String, dynamic>>?> getListUnspent(String scriptHash) async {
    final result = await call(method: 'blockchain.scripthash.listunspent', params: [scriptHash]);

    if (result is List) {
      return result.map((dynamic val) {
        if (val is Map<String, dynamic>) {
          return val;
        }

        return <String, dynamic>{};
      }).toList();
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getMempool(String scriptHash) =>
      call(method: 'blockchain.scripthash.get_mempool', params: [scriptHash])
          .then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, dynamic>) {
              return val;
            }

            return <String, dynamic>{};
          }).toList();
        }

        return [];
      });

  Future<dynamic> getTransaction({required String hash, required bool verbose}) async {
    try {
      final result = await callWithTimeout(
          method: 'blockchain.transaction.get', params: [hash, verbose], timeout: 10000);
      return result;
    } on RequestFailedTimeoutException catch (_) {
      return <String, dynamic>{};
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  Future<Map<String, dynamic>> getTransactionVerbose({required String hash}) =>
      getTransaction(hash: hash, verbose: true).then((dynamic result) {
        if (result is Map<String, dynamic>) {
          return result;
        }

        return <String, dynamic>{};
      });

  Future<String> getTransactionHex({required String hash}) =>
      getTransaction(hash: hash, verbose: false).then((dynamic result) {
        if (result is String) {
          return result;
        }

        return '';
      });

  Future<String> broadcastTransaction(
          {required String transactionRaw,
          BasedUtxoNetwork? network,
          Function(int)? idCallback}) async =>
      call(
              method: 'blockchain.transaction.broadcast',
              params: [transactionRaw],
              idCallback: idCallback)
          .then((dynamic result) {
        if (result is String) {
          return result;
        }

        return '';
      });

  Future<Map<String, dynamic>> getMerkle({required String hash, required int height}) async =>
      await call(method: 'blockchain.transaction.get_merkle', params: [hash, height])
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getHeader({required int height}) async =>
      await call(method: 'blockchain.block.get_header', params: [height]) as Map<String, dynamic>;

  BehaviorSubject<Object>? tweaksSubscribe({required int height, required int count}) {
    return subscribe<Object>(
      id: 'blockchain.tweaks.subscribe',
      method: 'blockchain.tweaks.subscribe',
      params: [height, count, false],
    );
  }

  Future<dynamic> getTweaks({required int height}) async =>
      await callWithTimeout(method: 'blockchain.tweaks.subscribe', params: [height, 1, false]);

  Future<double> estimatefee({required int p}) =>
      call(method: 'blockchain.estimatefee', params: [p]).then((dynamic result) {
        if (result is double) {
          return result;
        }

        if (result is String) {
          return double.parse(result);
        }

        return 0;
      });

  Future<List<List<int>>> feeHistogram() =>
      call(method: 'mempool.get_fee_histogram').then((dynamic result) {
        if (result is List) {
          // return result.map((dynamic e) {
          //   if (e is List) {
          //     return e.map((dynamic ee) => ee is int ? ee : null).toList();
          //   }

          //   return null;
          // }).toList();
          final histogram = <List<int>>[];
          for (final e in result) {
            if (e is List) {
              final eee = <int>[];
              for (final ee in e) {
                if (ee is int) {
                  eee.add(ee);
                }
              }
              histogram.add(eee);
            }
          }
          return histogram;
        }

        return [];
      });

  Future<List<int>> feeRates({BasedUtxoNetwork? network}) async {
    try {
      final topDoubleString = await estimatefee(p: 1);
      final middleDoubleString = await estimatefee(p: 5);
      final bottomDoubleString = await estimatefee(p: 10);
      final top = (stringDoubleToBitcoinAmount(topDoubleString.toString()) / 1000).round();
      final middle = (stringDoubleToBitcoinAmount(middleDoubleString.toString()) / 1000).round();
      final bottom = (stringDoubleToBitcoinAmount(bottomDoubleString.toString()) / 1000).round();

      return [bottom, middle, top];
    } catch (_) {
      return [];
    }
  }

  // https://electrumx.readthedocs.io/en/latest/protocol-methods.html#blockchain-headers-subscribe
  // example response:
  // {
  //   "height": 520481,
  //   "hex": "00000020890208a0ae3a3892aa047c5468725846577cfcd9b512b50000000000000000005dc2b02f2d297a9064ee103036c14d678f9afc7e3d9409cf53fd58b82e938e8ecbeca05a2d2103188ce804c4"
  // }

  Future<int?> getCurrentBlockChainTip() async {
    try {
      final result = await callWithTimeout(method: 'blockchain.headers.subscribe');
      if (result is Map<String, dynamic>) {
        return result["height"] as int;
      }
      return null;
    } on RequestFailedTimeoutException catch (_) {
      return null;
    } catch (e) {
      printV("getCurrentBlockChainTip: ${e.toString()}");
      return null;
    }
  }

  BehaviorSubject<Object>? chainTipSubscribe() {
    _id += 1;
    return subscribe<Object>(
        id: 'blockchain.headers.subscribe', method: 'blockchain.headers.subscribe');
  }

  BehaviorSubject<Object>? scripthashUpdate(String scripthash) {
    _id += 1;
    return subscribe<Object>(
        id: 'blockchain.scripthash.subscribe:$scripthash',
        method: 'blockchain.scripthash.subscribe',
        params: [scripthash]);
  }

  BehaviorSubject<T>? subscribe<T>(
      {required String id, required String method, List<Object> params = const []}) {
    try {
      if (socket == null) {
        return null;
      }
      final subscription = BehaviorSubject<T>();
      _regisrySubscription(id, subscription);
      printV("[ELECTRUM_SUB] id=$_id method=$method subscriptionKey=$id");
      socket!.write(jsonrpc(method: method, id: _id, params: params));

      return subscription;
    } catch (e) {
      printV("subscribe $e");
      return null;
    }
  }

  Future<dynamic> call(
      {required String method, List<Object> params = const [], Function(int)? idCallback}) async {
    if (!isConnected) return null;
    final completer = Completer<dynamic>();
    _id += 1;
    final id = _id;
    printV("[${method}] call with $_id started with params: $params");
    idCallback?.call(id);
    _registryTask(id, completer);
    _requestCount++;
    _requestsThisConnection++;
    final _reqNow = DateTime.now();
    _recentRequestTimestamps.add(_reqNow);
    _recentRequestTimestamps.removeWhere((t) => _reqNow.difference(t).inSeconds > 10);
    printV("[ELECTRUM_REQ] id=$id method=$method | session=#$_requestsThisConnection total=#$_requestCount req/s:${(_recentRequestTimestamps.length / 10.0).toStringAsFixed(2)}");
    printV("We write to socket: ${jsonrpc(method: method, id: id, params: params)}");
    socket!.write(jsonrpc(method: method, id: id, params: params));

    return completer.future;
  }

  Future<dynamic> batchCall(
      {required String batchJsonString, required String batchId, Function(int)? idCallback}) async {
    if (!isConnected) return null;
    final completer = Completer<dynamic>();
    _id += 1;
    final id = _id;
    printV("[batchCall: ${batchId}] call");
    idCallback?.call(id);
    _registryTask(id, completer);
    _requestCount++;
    _requestsThisConnection++;
    final _reqNow = DateTime.now();
    _recentRequestTimestamps.add(_reqNow);
    _recentRequestTimestamps.removeWhere((t) => _reqNow.difference(t).inSeconds > 10);
    printV("[ELECTRUM_REQ] id=$batchId | session=#$_requestsThisConnection total=#$_requestCount req/s:${(_recentRequestTimestamps.length / 10.0).toStringAsFixed(2)}");
    printV("We write a batch to socket with id $id: $batchJsonString");
    socket!.write(batchJsonString + '\n');

    return completer.future;
  }

  Future<dynamic> callWithTimeout(
      {required String method, List<Object> params = const [], int timeout = 5000}) async {
    try {
      if (!isConnected) return null;

      final completer = Completer<dynamic>();
      _id += 1;
      final id = _id;
      _registryTask(id, completer);
      _requestCount++;
      _requestsThisConnection++;
      final _reqNow = DateTime.now();
      _recentRequestTimestamps.add(_reqNow);
      _recentRequestTimestamps.removeWhere((t) => _reqNow.difference(t).inSeconds > 10);
      printV("[ELECTRUM_REQ] id=$id method=$method (timeout=${timeout}ms) | session=#$_requestsThisConnection total=#$_requestCount req/s:${(_recentRequestTimestamps.length / 10.0).toStringAsFixed(2)}");
      socket!.write(jsonrpc(method: method, id: id, params: params));
      Timer(Duration(milliseconds: timeout), () {
        if (!completer.isCompleted) {
          completer.completeError(RequestFailedTimeoutException(method, id));
        }
      });

      return completer.future;
    } catch (e) {
      printV("callWithTimeout $e");
      rethrow;
    }
  }

  Future<void> close() async {
    _aliveTimer?.cancel();
    try {
      await socket?.close();
      socket = null;
    } catch (_) {}
    onConnectionStatusChange = null;
    // Reset internal state when closing
    _resetInternalStateCompletely();
  }

  void _resetInternalState() {
    // Only clears errors and unterminated string, leaves tasks or reset ID
    // This preserves active subscriptions while clearing error state
    _errors.clear();
    unterminatedString = '';
  }

  void _resetInternalStateCompletely() {
    _id = 0;
    _tasks.clear();
    _errors.clear();
    unterminatedString = '';
    _requestsThisConnection = 0;
    _recentRequestTimestamps.clear();
  }

  void _registryTask(int id, Completer<dynamic> completer) =>
      _tasks[id.toString()] = SocketTask(completer: completer, isSubscription: false);

  void _regisrySubscription(String id, BehaviorSubject<dynamic> subject) =>
      _tasks[id] = SocketTask(subject: subject, isSubscription: true);

  void _finish(String id, Object? data) {
    if (_tasks[id] == null) {
      return;
    }

    if (!(_tasks[id]?.completer?.isCompleted ?? false)) {
      _tasks[id]?.completer!.complete(data);
    }

    if (!(_tasks[id]?.isSubscription ?? false)) {
      _tasks.remove(id);
    } else {
      _tasks[id]?.subject?.add(data);
    }
  }

  void _methodHandler({required String method, required Map<String, dynamic> request}) {
    switch (method) {
      case 'blockchain.headers.subscribe':
        final params = request['params'] as List<dynamic>;
        final id = 'blockchain.headers.subscribe';

        _tasks[id]?.subject?.add(params.last);
        break;
      case 'blockchain.scripthash.subscribe':
        final params = request['params'] as List<dynamic>;
        final scripthash = params.first as String?;
        final id = 'blockchain.scripthash.subscribe:$scripthash';

        _tasks[id]?.subject?.add(params.last);
        break;
      case 'blockchain.headers.subscribe':
        final params = request['params'] as List<dynamic>;
        _tasks[method]?.subject?.add(params.last);
        break;
      case 'blockchain.tweaks.subscribe':
        final params = request['params'] as List<dynamic>;
        _tasks[_tasks.keys.first]?.subject?.add(params.last);
        break;
      default:
        break;
    }
  }

  void _setConnectionStatus(ConnectionStatus status) {
    final now = DateTime.now();
    
    if (status == ConnectionStatus.connected) {
      if (_disconnectedAt != null) {
        final reconnectMs = now.difference(_disconnectedAt!).inMilliseconds;
        printV("[ELECTRUM_CONNECT] Reconnected after ${reconnectMs}ms (disconnected at $_disconnectedAt)");
      } else {
        printV("[ELECTRUM_CONNECT] Connected at $now");
      }
      _connectionEstablishedAt = now;
      _requestsThisConnection = 0;
      _disconnectedAt = null;
      // Reset backoff on successful connection
      _consecutiveFailures = 0;
      // Restart ping timer
      keepAlive();
    } else if (status == ConnectionStatus.disconnected || status == ConnectionStatus.failed) {
      _disconnectedAt = now;
      if (_connectionEstablishedAt != null) {
        final sessionSecs = now.difference(_connectionEstablishedAt!).inSeconds;
        printV("[ELECTRUM_DISCONNECT] status=$status | session lasted ${sessionSecs}s | requests this session: $_requestsThisConnection | total requests: $_requestCount");
      } else {
        printV("[ELECTRUM_DISCONNECT] status=$status at $now (no prior connection recorded)");
      }
      // Increment failure counter and calculate next backoff
      _consecutiveFailures++;
      final nextDelay = getReconnectionDelay();
      printV("[BACKOFF] Failure #$_consecutiveFailures, next retry in ${nextDelay.inSeconds}s");
      // Stop ping timer during disconnection
      _aliveTimer?.cancel();
      _aliveTimer = null;
    }
    onConnectionStatusChange?.call(status);
    _connectionStatus = status;
    if (!isConnected) {
      try {
        socket?.destroy();
      } catch (_) {}
      socket = null;
    }
  }

  void _handleResponse(Map<String, dynamic> response) {
    final method = response['method'];
    final id = response['id'] as String?;
    final result = response['result'];

    try {
      final error = response['error'] as Map<String, dynamic>?;
      if (error != null) {
        final errorMessage = error['message'] as String?;
        if (errorMessage != null) {
          _errors[id!] = errorMessage;
        }
      }
    } catch (_) {}

    try {
      final error = response['error'] as String?;
      if (error != null) {
        _errors[id!] = error;
      }
    } catch (_) {}

    if (method is String) {
      _methodHandler(method: method, request: response);
      return;
    }

    if (id != null) {
      _finish(id, result);
    }
  }

  String getErrorMessage(int id) => _errors[id.toString()] ?? '';

  bool get isInternalStateConsistent => _errors.isEmpty;

  /// The ID of the most recently dispatched request — use for log correlation.
  int get lastRequestId => _id;
}

// FIXME: move me
bool isJSONStringCorrect(String source) {
  try {
    json.decode(source);
    return true;
  } catch (_) {
    return false;
  }
}

class RequestFailedTimeoutException implements Exception {
  RequestFailedTimeoutException(this.method, this.id);

  final String method;
  final int id;
}
