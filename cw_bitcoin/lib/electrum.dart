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
  // ── Batching ─────────────────────────────────────────────────────────────────
  Map<String, String> batchMethodMap = {};
  Map<String, String> batchToAddress = {};
  Map<String, String> batchToScripthash = {};

  // ─────────────────────────────────────────────────────────────────────────────

  String serverVersion = '';

  void _applyBatchResultToAddress(
      BitcoinAddressRecord addressRecord, String method, dynamic result) {
    switch (method) {
      case 'blockchain.scripthash.get_history':
        if (result is List) {
          addressRecord.txCount = result.length;
          if (result.isNotEmpty) {
            addressRecord.setAsUsed();
          }
        }
        break;
      case 'blockchain.scripthash.get_balance':
        if (result is Map<String, dynamic>) {
          final confirmed = result['confirmed'] as int? ?? 0;
          final unconfirmed = result['unconfirmed'] as int? ?? 0;
          addressRecord.balance = confirmed + unconfirmed;
          if (addressRecord.balance > 0) {
            addressRecord.setAsUsed();
          }
        }
        break;
      case 'blockchain.scripthash.listunspent':
        if (result is List) {
          var total = 0;
          for (final item in result) {
            if (item is Map<String, dynamic>) {
              total += item['value'] as int? ?? 0;
            }
          }
          addressRecord.balance = total;
          if (total > 0) {
            addressRecord.setAsUsed();
          }
        }
        break;
      default:
        break;
    }
  }

  // Future<dynamic> getHistoryData(List<String> scriptHashes) async {
  //   batchGetData(scriptHashes, 'blockchain.scripthash.get_history');
  //   for (var i = 0; i < scriptHashes.length; i++) {
  //     final sh = scriptHashes[i];
  //     printV('getHistoryData: Requested history for scripthash $sh');
  //   }
  // }

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

  Future<dynamic> batchGetData(
      List<BitcoinAddressRecord> addresses, String method, BasedUtxoNetwork network) async {
    // throw UnimplementedError("Deprecated");
    if (addresses.isEmpty) {
      return {};
    }

    try {
      // OPTIMIZATION: Split into batches of max 50 operations
      const int maxBatchSize = 50;
      final List<dynamic> allResults = [];

      // We're not going to loop the whole dataset here
      // Loop the data in the invoking function so we can save results even when future batches fail
      for (int batchStart = 0; batchStart < addresses.length; batchStart += maxBatchSize) {
        final batchEnd = (batchStart + maxBatchSize < addresses.length)
            ? batchStart + maxBatchSize
            : addresses.length;
        final batchAddresses = addresses.sublist(batchStart, batchEnd);

        // Build batch request payload for this chunk
        final List<Map<String, dynamic>> batchRequest = [];
        final int batchStartId = batchStart;
        final int batchEndId = batchEnd - 1;
        _id++;
        final int batchUniqueId = _id;
        final String batchId = 'batch_${batchStartId}_${batchEndId}_${batchUniqueId}';

        // We already incremented _id - so it is in sync
        batchToAddress[batchId] = batchAddresses[0].address;
        batchToScripthash[batchId] = batchAddresses[0].getScriptHash(network);
        batchMethodMap[batchId] = method;
        for (int i = 0; i < batchAddresses.length; i++) {
          batchRequest.add({
            'jsonrpc': '2.0',
            'id': batchId,
            'method': method,
            'params': [batchAddresses[i].getScriptHash(network)],
          });
        }

        final batchRequestJson = json.encode(batchRequest);
        printV(
            'batchGetData: Sending batch ${batchStart ~/ maxBatchSize + 1} of ${(addresses.length / maxBatchSize).ceil()} (${batchAddresses.length} operations)');

        // Send batch request
        if (!isConnected) {
          throw Exception('Not connected to Electrum server');
        }

        // Use a special string ID for batch requests to avoid conflicts
        final completer = Completer<dynamic>();
        //final batchId = 'batch_${batchStartId}_${_id}';
        _tasks[batchId] = SocketTask(completer: completer, isSubscription: false);
        printV(_tasks);

        // Write the batch request directly to socket
        socket!.write(batchRequestJson + '\n');
        printV(
            'batchGetData: Batch request sent with ID range: ${batchStartId}-${batchEndId} (batch key: $batchId)');
        final response = await completer.future.timeout(
          Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Batch request timed out after 60 seconds');
          },
        );

        if (response is List<dynamic>) {
          final responseLen = response.length;
          final expectedLen = batchAddresses.length;
          if (responseLen != expectedLen) {
            printV(
                'batchGetData: response length mismatch for $batchId (expected $expectedLen, got $responseLen)');
          }

          final updateCount = responseLen < expectedLen ? responseLen : expectedLen;
          for (int i = 0; i < updateCount; i++) {
            final item = response[i];
            if (item is! Map<String, dynamic>) {
              continue;
            }

            final targetAddress = batchAddresses[i];
            final result = item['result'];
            _applyBatchResultToAddress(targetAddress, method, result);

            printV(
                'batchGetData: updated address index ${batchStart + i} (${targetAddress.address}) for method $method');
          }

          allResults.addAll(response);
        }

        // OPTIMIZATION: 1000ms delay between batches to allow server processing time
        // This prevents overwhelming Fulcrum's request queue and gives it time to query bitcoind
        if (batchEnd < addresses.length) {
          await Future.delayed(Duration(milliseconds: 1000));
        }
      }

      return allResults;
    } catch (e) {
      printV('batchGetResponse error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> batchCallByChunks({
    required String method,
    required List<List<Object>> paramsList,
    int maxBatchSize = 50,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (paramsList.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    if (!isConnected) {
      throw Exception('Not connected to Electrum server');
    }

    final allResults = <Map<String, dynamic>>[];

    for (int batchStart = 0; batchStart < paramsList.length; batchStart += maxBatchSize) {
      final batchEnd = (batchStart + maxBatchSize < paramsList.length)
          ? batchStart + maxBatchSize
          : paramsList.length;
      final chunk = paramsList.sublist(batchStart, batchEnd);

      _id++;
      final batchBaseId = _id;
      final batchId = 'batch_call_${method}_${batchStart}_${batchEnd - 1}_$batchBaseId';

      final batchRequest = <Map<String, dynamic>>[];
      for (int i = 0; i < chunk.length; i++) {
        batchRequest.add({
          'jsonrpc': '2.0',
          'id': '$batchId:$i',
          'method': method,
          'params': chunk[i],
        });
      }

      final completer = Completer<dynamic>();
      _tasks[batchId] = SocketTask(completer: completer, isSubscription: false);
      socket!.write('${json.encode(batchRequest)}\n');

      final response = await completer.future.timeout(
        timeout,
        onTimeout: () =>
            throw TimeoutException('Batch request timed out after ${timeout.inSeconds} seconds'),
      );

      if (response is List) {
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            allResults.add(item);
          }
        }
      }

      if (batchEnd < paramsList.length) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    return allResults;
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

    // Currently sort of interprets tx_hash results for batch get_history calls
    //
    /*  Map<String, String> batchMethodMap = {};
  Map<String, String> batchToAddress = {};
  Map<String, String> batchToScripthash = {};

Completer code

          final task = _tasks[batchId];
                  if (task != null &&
                      !task.isSubscription &&
                      task.completer != null &&
                      !task.completer!.isCompleted) {
                    task.completer!.complete(decoded);
                    _tasks.remove(batchId);
                    printV('Completed batch request $batchId with ${decoded.length} results');


  */
    void _handleBatchResponse(String message) {
      try {
        final decoded = json.decode(message);

        if (decoded is! List) {
          printV('Unexpected batch response format: $decoded');
          return;
        }

        printV('Received batch response with ${decoded.length} items');

        if (decoded.isEmpty) {
          printV('Warning: Received empty batch response');
          return;
        }

        final batchResponses = decoded.whereType<Map<String, dynamic>>().toList();
        if (batchResponses.isEmpty) {
          printV('Warning: Batch response has no valid response items');
          return;
        }

        final firstId = batchResponses.first['id'];
        String? batchId;

        if (firstId is String) {
          final separatorIndex = firstId.indexOf(':');
          batchId = separatorIndex > 0 ? firstId.substring(0, separatorIndex) : firstId;
        } else if (firstId is int) {
          final ids = batchResponses.map((item) => item['id']).whereType<int>().toList()..sort();
          if (ids.isNotEmpty) {
            batchId = 'batch_${ids.first}_${ids.last}';
          }
        }

        if (batchId == null) {
          printV('Warning: Could not determine batch task key from response');
          return;
        }

        printV('Looking for batch task with key: $batchId');
        printV('Batch method: ${batchMethodMap[batchId]}');
        printV('Batch address: ${batchToAddress[batchId]}');

        final task = _tasks[batchId];
        if (task != null &&
            !task.isSubscription &&
            task.completer != null &&
            !task.completer!.isCompleted) {
          task.completer!.complete(decoded);
          _tasks.remove(batchId);
          printV('Completed batch request $batchId with ${decoded.length} results');
          return;
        }

        printV(
            'Warning: No matching batch task found for $batchId. Available tasks: ${_tasks.keys.where((k) => k.startsWith("batch")).toList()}');
      } catch (e) {
        printV('Error handling batch response: $e');
      }
    }

    String msgStr = "";
    // use ping to determine actual connection status since we could've just not timed out yet:
    // _setConnectionStatus(ConnectionStatus.connected);
    socket!.listen(
      (Uint8List event) {
        try {
          final msg = utf8.decode(event.toList());
          msgStr += msg;
          final messagesList = msgStr.split("\n");
          msgStr = messagesList.removeLast();

          for (var message in messagesList) {
            // For some reason, some servers will serve us garbage whitespace characters
            // Skip empty messages or messages with only whitespace/control chars
            message = message.trim();
            if (message.isEmpty || message.replaceAll(RegExp(r'[\s\x00-\x1F\x7F]'), '').isEmpty) {
              continue;
            }
            printV("Received message: $message");
            if (message.startsWith('[')) {
              _handleBatchResponse(message);
            } else {
              _parseResponse(message);
            }
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
        printV("SOCKET CLOSED!");
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
      printV("Decoded message: $decoded");
      printV(decoded);
      if (decoded is Map<String, dynamic>) {
        // Handle single response
        printV(
            "Received response for message ID: ${decoded['id']} with method: ${decoded['method']}");
        _handleResponse(decoded);
      } else if (decoded is List) {
        printV('Single-response parser received a batch payload; routing skipped.');
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
    printV(
        "[ELECTRUM_REQ] id=$id method=$method | session=#$_requestsThisConnection total=#$_requestCount req/s:${(_recentRequestTimestamps.length / 10.0).toStringAsFixed(2)}");
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
    printV(
        "[ELECTRUM_REQ] batch id=$id | session=#$_requestsThisConnection total=#$_requestCount req/s:${(_recentRequestTimestamps.length / 10.0).toStringAsFixed(2)}");
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
      printV(
          "[ELECTRUM_REQ] id=$id method=$method (timeout=${timeout}ms) | session=#$_requestsThisConnection total=#$_requestCount req/s:${(_recentRequestTimestamps.length / 10.0).toStringAsFixed(2)}");
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
        printV(
            "[ELECTRUM_CONNECT] Reconnected after ${reconnectMs}ms (disconnected at $_disconnectedAt)");
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
        printV(
            "[ELECTRUM_DISCONNECT] status=$status | session lasted ${sessionSecs}s | requests this session: $_requestsThisConnection | total requests: $_requestCount");
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

/* DEBUG OUTPUT 
            // We can't have two listeners to a single socket, so we pass off batchResponse handling as soon as possible
            // if (isBatchResponse) {
            //   printV("Received batch response: $msg");
            //   msg.trim();
            //   msg.replaceAll(RegExp(r'[\s\x00-\x1F\x7F]'), '');
            //   var str1 =
            //       '[{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":852088,"tx_hash":"5d5133801231eec3d50f26a67ce93a381dac0f32542c7487e63d52fb81ff62cb"},{"height":856174,"tx_hash":"5397120f2dd8d5640988c3c41ea2530b69cb39167f5fab0bac4b8f0e32f5985d"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":847406,"tx_hash":"598a2e0b97f5d2aa563fd20dec870340734116e009683fcba7b95eaf6da45226"},{"height":849581,"tx_hash":"282f9d307dc8e5d4cdf762959865434b49288cfe2a803a7011b79df8c1d071fa"},{"height":869461,"tx_hash":"0f3a379f00170ee2b54b4f5e48ae6a33802763d3ed436b61dd9767af4d85f961"},{"height":869474,"tx_hash":"d48f4f80545e4ee2104480cff7990ae474bfbad2a403307e55544240d7a88d22"},{"height":873385,"tx_hash":"7bfe910e51a899601a6d7114589a497888c29a4b39bcb694fd938cedc704c533"},{"height":875337,"tx_hash":"0ff2fc59debb6e55ef58d580f052fb08d95bb87163e1720b34a64696dd3642ba"},{"height":877129,"tx_hash":"f8cb4c0f26920eab19fa92359dc00eea6fea7ba58c00a2e35efeffd3bbcdb8fd"},{"height":877688,"tx_hash":"7287aa4b0be1ff4cd9a98c9362e6f6e5891e904f5b48fb01495216748a2c20ba"},{"height":892266,"tx_hash":"6fe155e46259854f1e0dcbcd7065c0e967805a2ad490b7cf7314438657a35162"},{"height":892286,"tx_hash":"cdc64e06ac2ea2edf491f73565614e793d75973fedc9484cc834ecabfba9234c"},{"height":894746,"tx_hash":"52e7befb80dbb05884d23e7c401b6a17a28d6f41c98500434f466d013d310007"},{"height":898060,"tx_hash":"ee2a13ae82bba359263c059a4844a314baa96a5085b95c7d8dd4ec84683d8813"},{"height":898261,"tx_hash":"af58c7c610f6b2cf16eb42f0173158020e5987dca5988e050af6d4d22023ec55"},{"height":898262,"tx_hash":"52352d49f449b5f1b28d7c070f8b51d5de89311e188faa0db36f2a01f573e633"},{"height":905998,"tx_hash":"34e5c491066ac0b5751176c0f594f76e9fa37451fad71e2d7193759205d55fb8"},{"height":905998,"tx_hash":"87295464379aea774e30b43cb2a10cc1416a926006c94c536445c6cae635c475"},{"height":915414,"tx_hash":"6e70e824f151caa7c472fea8b357ae0bdf294dd74bc65fa623dd6fb5c37f8abc"},{"height":916346,"tx_hash":"cf2097646aac896fca40e8297f5b69ec8407218e4aa5dce99b7961edb7584e1e"},{"height":917483,"tx_hash":"30be76b4bea8f8385316148bd78a0611755c7de62ee52efb3193a433354bcf0e"},{"height":917901,"tx_hash":"78577311104b29e5e1f88f9af84eb3e24eb4d61440bffa335be2b803292622d2"},{"height":918176,"tx_hash":"ad2a30e88000379bb463c90ba2eb4ac36fdfda4636497474b34d443b0e48f625"},{"height":918320,"tx_hash":"9fb277be54d49dea6592aeaf62f4c25490caacab1aee8028df3dc4ce178d351c"},{"height":937080,"tx_hash":"f0dc97d20b29bdbd8b67fa4918977434d52d5dd4e521bb47e583419a6e8e5760"},{"height":937106,"tx_hash":"92300b6714596d838646ab1d04cd7e401ee484e23290208fb931ccb6063b6ce9"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":869474,"tx_hash":"93cf1e6512b3e608535d2af1fbdd55a26dc4239015b9bcd8bfa7ca3c1640e5b2"},{"height":869676,"tx_hash":"d21f93dd15e1add13b251b77ba486842fe2682ba4d80e44ecdfa1fc8c3ac3af6"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":867329,"tx_hash":"a8496810afe5015579571dbf601fdc34529c92e11fb575b29501f8a6d7f8c51c"},{"height":867595,"tx_hash":"984b3982b7137eaf464d46269a0ba25273f14791468f72c40a698c1a3ae48b7a"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":877985,"tx_hash":"0cbb08261c631334fc8dcf2d1b1000df4e1b886663ec9fde571b19f7c8257cd8"},{"height":878493,"tx_hash":"8ece735cf6d2a82c52c3829d468ca51f1e42d77b5708b8f840d18aa02b761f46"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":865675,"tx_hash":"d612bb2b47a10be7d31c991da9123ab3ce01a3fbd423239fba89e08fea13242b"},{"height":866263,"tx_hash":"98cd2eee99479395a3c5b932a5aab0f5fbfd8e22820c1910e567a4c660f65afa"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":875329,"tx_hash":"f71f99d57efa482d8648817c647cae2f19547beeed00cdfacbb7a6a857d9ee2b"},{"height":875337,"tx_hash":"0ff2fc59debb6e55ef58d580f052fb08d95bb87163e1720b34a64696dd3642ba"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":894100,"tx_hash":"cd541184cad3385f446f5b79b7619b64eb7bbb8b7f42d20bccf9d29612df2eb6"},{"height":894751,"tx_hash":"1b2b4bc9340e28000bdbb1cdf82d462b9a9736cd8a5b5aa6149e265ff83fbab8"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":896642,"tx_hash":"46d123beac1c7b9b0496c1b7f129d4773fc1725ea891cb5674fd9a1207799053"},{"height":896645,"tx_hash":"af0727a14e243266852d094beec5dc0fa343ded07030aa883d1706b580cf7620"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":898131,"tx_hash":"3a54648d578e99a37e40cb1db7131f6db33ba806f92654cf97bd91754c1c24ce"},{"height":898131,"tx_hash":"c2f41197d47b2f41da4406f41cb1019473965e3c0c377eec5bd42ac8d96548e8"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":898265,"tx_hash":"873c7178f16b877608cbab6dbd18779e64c9fa7e4f946bc7d8919b33e2627433"},{"height":898479,"tx_hash":"e195927bb60ba5bbdf14651bae625af8529e40c443226ccc41bc0d5d56aecc10"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":879555,"tx_hash":"94781d4a421b3743714ec367a27d94df17b1ca5c74ffae8f7e95d7fff5294c07"},{"height":879567,"tx_hash":"11e21acb04156467b4f9c6f2a487221e07720398af4dd059cf61cc89d856c618"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":898538,"tx_hash":"163e804e9d582ca03d8f77de6a9347ee04780a7a66e0751fb8a69d31cb098150"},{"height":898540,"tx_hash":"7419f93b83841eb299312430edc58333ab4adc7e21bd5e14ccd82b63a5a4aba2"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":898542,"tx_hash":"fedf2e63e0170a5348258baf1254d9cf0e674e3c995d30b2fdbaf940a5f5dc8b"},{"height":900749,"tx_hash":"0615c68c9886118824ad62d7303437cfcd9d9b367c1ea73ba4874ea59b72e64f"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":900750,"tx_hash":"b8e34b912d0ecbb98a8f611031e0a68ba2ebbc027c43c61c55e140501a54ebd6"},{"height":900751,"tx_hash":"30975a4546c2a88e0f02d68e8127efed6d2bbab1817612d42e1da5a264d146ae"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":876896,"tx_hash":"df4b98b454cc40c57a5c1329ba21a5fe17a937e9ed1687e346edf9378013f826"},{"height":877118,"tx_hash":"2ff38b7845d736040a684457ec5a97bb47f9f50f00f703fe1826e412bb916fcd"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":901651,"tx_hash":"f9e5f9ef18d6eb89baa8e443337ece69fa6ec17e7209ee6cdf7af366352971fc"},{"height":901656,"tx_hash":"da8cdf8629fb5567336120095553b671dfab1972dd86be4c2e8f9bfc0e302c9e"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":851911,"tx_hash":"69a3c6f1a1598fa5588ba2d3f0d18807716bc16fffc588f535d12257758c238d"},{"height":851936,"tx_hash":"833ca548be9e77d2a529a8b2bdccb9f50b8d91b2004bf7913ea49475780f1bf4"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":848088,"tx_hash":"188abd743227083770e3a12869c65bc790b8808bd7e7c54aca72ba8f7ef689df"},{"height":850297,"tx_hash":"1d72a78a0e892cef7a7aeb791a3752c176971c88df70494a2b457412b34f2292"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":851714,"tx_hash":"837640a0de4cad9c671c09042fa80b6b7e285733f9a38120e32d897138b44d0d"},{"height":856194,"tx_hash":"c55f08181d54274ff5287ee43677b56e59cc8b86c5b4d64be83a8942d0130ace"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":849581,"tx_hash":"282f9d307dc8e5d4cdf762959865434b49288cfe2a803a7011b79df8c1d071fa"},{"height":850297,"tx_hash":"1d72a78a0e892cef7a7aeb791a3752c176971c88df70494a2b457412b34f2292"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":846092,"tx_hash":"47ebbecdb90166798d45876c48f65e20e6b73b565f3b6d3d3fc3169d90319384"},{"height":848088,"tx_hash":"188abd743227083770e3a12869c65bc790b8808bd7e7c54aca72ba8f7ef689df"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":850297,"tx_hash":"1d72a78a0e892cef7a7aeb791a3752c176971c88df70494a2b457412b34f2292"},{"height":851714,"tx_hash":"837640a0de4cad9c671c09042fa80b6b7e285733f9a38120e32d897138b44d0d"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":892286,"tx_hash":"591f43ca1f996761e9548fe5fb61a50d63abe1ecd083ad67a5de284ff7833746"},{"height":892292,"tx_hash":"41064b9a0d1a06671fc7581d08223090b15a20e029833bbcd78cd6d18cd6b983"},{"height":898482,"tx_hash":"72389082d82ce787aad69ef0ad4f7986240235be1b206a146d27d96ca50f80dc"},{"height":898485,"tx_hash":"c66379d65c1b5675c3e0349aa1427ebcdef579e1d7e77df2d713c6ebf3822ec0"},{"height":898534,"tx_hash":"59287a3c92e8b56c7e6ec2aa2a2e98424ca6d4055c73a7863f9eeca851c3b432"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":856181,"tx_hash":"3a33"';
            //   var str2 =
            //       'f4bee27979001294f9e04cd671ad98a5cdfeed90fe9da2cbc201174594a4"},{"height":856459,"tx_hash":"30eee10550f29b6995991cc530df91a25d522488c50118595a4cc27f2c6da686"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":856174,"tx_hash":"5397120f2dd8d5640988c3c41ea2530b69cb39167f5fab0bac4b8f0e32f5985d"},{"height":856181,"tx_hash":"3a33f4bee27979001294f9e04cd671ad98a5cdfeed90fe9da2cbc201174594a4"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":843091,"tx_hash":"18cfc631f1704675c0cc845f5091986bad6f0649bd73930b4b35d3aabedb1ab6"},{"height":848088,"tx_hash":"188abd743227083770e3a12869c65bc790b8808bd7e7c54aca72ba8f7ef689df"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":901124,"tx_hash":"3b3f0c61f7e24bdba998366393d9bb8611c92afa3e3cd9aa2469c5e589fba907"},{"height":901413,"tx_hash":"ee836319d1ba7090634dadd60f4940abd40d577e7f632e6ce44cb338006805e9"},{"height":901530,"tx_hash":"e23b65d7ead94c4fddc9a2f2382453711808200210be413294744099c59fc170"},{"height":901531,"tx_hash":"cf6963664325e0c507df6ad19044545b393dabc6ae08056cc53fe1e370148e9a"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":861736,"tx_hash":"4aa9423c37b4bc9128c0dca69afe11c9f03e4886424f9dabe927c075fa5a482a"},{"height":866263,"tx_hash":"98cd2eee99479395a3c5b932a5aab0f5fbfd8e22820c1910e567a4c660f65afa"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":866263,"tx_hash":"98cd2eee99479395a3c5b932a5aab0f5fbfd8e22820c1910e567a4c660f65afa"},{"height":866298,"tx_hash":"43e296565d11c223683f62e3715d79d7c4a65bb593884c8adac01146e11081e5"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":858861,"tx_hash":"04aa9c53480b831b20f8e6f2c40e2b532338f2495460cc089c558d3e30abe936"},{"height":859000,"tx_hash":"73be2f26b3e68999f166fabbb24024b3be77d72b88d39c21648683189f6b74c7"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":875337,"tx_hash":"0ff2fc59debb6e55ef58d580f052fb08d95bb87163e1720b34a64696dd3642ba"},{"height":875451,"tx_hash":"3c54bf61a0357fd6fb9156d52ac347464d9b40201cc6826872b1d6276d4b5761"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":875758,"tx_hash":"b52fe8cbef6083ecf782de68b400c58851d4734d596ec4fb147fc1556ca35e3d"},{"height":876881,"tx_hash":"19985877345e6ec21426300e426f08338f480e271128df8828f2857264fa9a79"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":901531,"tx_hash":"cf6963664325e0c507df6ad19044545b393dabc6ae08056cc53fe1e370148e9a"},{"height":901533,"tx_hash":"8638e2cc9270e5e73ccf2227c34c8e68b95071b4d704c7c2169d5eaf01b6b10e"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":869679,"tx_hash":"52be97202cb5bbb3db3bc365e6492729f3f02e5ee413aa8e17832f3e29d819c5"},{"height":869679,"tx_hash":"e0bd068b3407bee1f225440aa772ab9e5cb5cf20e474c6f9f9d2b7aae1096fed"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":907110,"tx_hash":"f060c9e64528a6bd31c34b62b98e35ae38a3f013bf9a73afad41962332ec220d"},{"height":907694,"tx_hash":"84a24257601be4141b7a425c86c4bc17538790041513152f3526ae1497e38c66"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":869679,"tx_hash":"e0bd068b3407bee1f225440aa772ab9e5cb5cf20e474c6f9f9d2b7aae1096fed"},{"height":869684,"tx_hash":"f8278646c8b3dfd87251063e780909e6d05099a7b09d6c71bae551a319219a99"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":937865,"tx_hash":"d37cf18f2af81fe0c54da900704132123a8fe3ccd4413ad47578551cfffd81a8"},{"height":937886,"tx_hash":"8df25e12a6f71e1496a680e8f9bcfafb171be43335ffcea51fd74f8d42c19a67"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":856459,"tx_hash":"30eee10550f29b6995991cc530df91a25d522488c50118595a4cc27f2c6da686"},{"height":858861,"tx_hash":"04aa9c53480b831b20f8e6f2c40e2b532338f2495460cc089c558d3e30abe936"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":877118,"tx_hash":"2ff38b7845d736040a684457ec5a97bb47f9f50f00f703fe1826e412bb916fcd"},{"height":877121,"tx_hash":"e8fa0e0bedfc1bb8f22a2b6a1cd7028ae500c230054b21e000c528dd61754cab"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":851936,"tx_hash":"833ca548be9e77d2a529a8b2bdccb9f50b8d91b2004bf7913ea49475780f1bf4"},{"height":856181,"tx_hash":"3a33f4bee27979001294f9e04cd671ad98a5cdfeed90fe9da2cbc201174594a4"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":877121,"tx_hash":"e8fa0e0bedfc1bb8f22a2b6a1cd7028ae500c230054b21e000c528dd61754cab"},{"height":877125,"tx_hash":"69af2bb2f6b7eebf63c0882c02f21b9442bec7668f9b679c2f4a90b5734e2798"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[{"height":907727,"tx_hash":"254181d456d79f96e49d858f0581d57139034fbf6421332e561f3ee1b511fa6b"},{"height":907816,"tx_hash":"95a351c0dd183507934524912b8c346f176f0fdde1b551428d7505871f96ad91"}]},{"id":"batch_0_49_2","jsonrpc":"2.0","result":[]}]';
            //   var testStr = str1 + str2;
            //   msg = testStr;
            //   if (isJSONStringCorrect(msg)) {
            //     unterminatedString += msg;
            //     printV("Batch response is a complete JSON string, handling batch response");
            //     _handleBatchResponse(msg);
            //     return;
            //   } else {
            //     printV(
            //         "Batch response is not a complete JSON string, appending to unterminatedString");
            //     unterminatedString += msg;
            //     return;
            //   }
            // } // By this point, we've handled batchResponse

*/
