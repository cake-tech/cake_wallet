import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
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
  // See callWithTimeout's comment on this method: electrs-tweaks's reply
  // never carries a matching id, so this is how _methodHandler finds the
  // right pending task for a one-shot blockchain.tweaks.subscribe call.
  String? _lastTweaksSubscribeRequestId;

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
        final msg = utf8.decode(event.toList());
        final messagesList = msg.split("\n");
        // Each message is parsed independently so a cast bug or malformed
        // shape in one reply (e.g. a batch/tweaks response) can't throw an
        // exception that aborts this loop and silently drops every other
        // reply queued in the same TCP chunk (which can include the reply
        // to an entirely unrelated request, like server.version).
        for (var message in messagesList) {
          if (message.isEmpty) {
            continue;
          }
          try {
            _parseResponse(message);
          } catch (e) {
            printV("socket.listen: $e");
          }
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

  void _parseResponse(String message) {
    try {
      final response = json.decode(message);
      _handleResponse(response);
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
        final response = json.decode(unterminatedString);
        _handleResponse(response);
        unterminatedString = '';
      }
    } on TypeError catch (e) {
      // json.decode above only throws FormatException for a syntactically
      // incomplete/invalid string — it never throws TypeError. So reaching
      // here means json.decode on `message` already succeeded and this
      // TypeError came from _handleResponse's own casts (e.g. a batch
      // response whose first item isn't a Map, or an unexpected params
      // shape) while processing a message that was already complete and
      // valid. Treating that as a partial fragment (the old behavior: append
      // it to unterminatedString and retry) was always wrong for this case —
      // it can permanently poison unterminatedString with a complete message
      // that will never combine with anything else into valid JSON again,
      // silently breaking all future fragment reassembly on this connection.
      // Just log and drop this one malformed-content message.
      printV("_parseResponse: TypeError handling '$message': $e");
    } catch (e) {
      printV("parse $e");
    }
  }

  bool _pingInFlight = false;

  void keepAlive() {
    _aliveTimer?.cancel();
    _aliveTimer = Timer.periodic(aliveTimerDuration, (_) async => ping());
  }

  Future<void> ping() async {
    // Without this guard, a ping stuck behind a large backlog (see below)
    // doesn't stop keepAlive's 5s timer from firing another one right on
    // top of it — piling on yet more traffic to a connection that's already
    // struggling to keep up.
    if (_pingInFlight) return;
    _pingInFlight = true;
    try {
      // A longer timeout than the default 5s: server.ping shares the same
      // TCP connection as everything else, so its reply can legitimately
      // queue up behind a large in-flight response (e.g. a big
      // tweaks.subscribe payload, or a burst of individual per-address
      // calls) without the connection actually being dead. A too-short ping
      // timeout here causes a disconnect/reconnect loop that keeps
      // aborting slow-but-alive requests before they finish.
      await callWithTimeout(method: 'server.ping', timeout: 20000);
      _setConnectionStatus(ConnectionStatus.connected);
    } catch (_) {
      // Escalating to "disconnected" here fires onConnectionStatusChange
      // unconditionally (before _setConnectionStatus's own isConnected
      // check even runs) — the wallet layer reacts by wiping every
      // scripthash subscription and re-subscribing the whole address list,
      // which dumps a fresh burst of traffic onto this same connection. If
      // the socket itself is still alive, a slow ping reply just means it's
      // busy, not dead — treating it as a disconnect was a self-reinforcing
      // loop: busy connection -> ping times out -> full resubscribe burst
      // -> connection even busier -> next ping times out too. Only treat
      // this as a real disconnect once the socket itself is actually gone.
      if (!isConnected) {
        _setConnectionStatus(ConnectionStatus.disconnected);
      }
    } finally {
      _pingInFlight = false;
    }
  }

  Future<List<String>> version() async {
    // `call()` has no timeout at all — its completer only resolves once a
    // response actually arrives, so if a request gets written to a socket
    // that *looks* connected (isConnected stays true — no error, no close
    // event) but the reply silently never comes back (a "black hole"
    // connection, plausible over this test node's unreliable network
    // path), this hangs forever. Every caller of getNodeIsElectrs() ->
    // getNodeSupportsSilentPayments() -> getNodeIsElectrsSPEnabled() then
    // hangs transitively too, freezing the whole "start scanning" flow
    // with no error, no timeout, nothing — exactly what was observed.
    try {
      final result =
          await callWithTimeout(method: 'server.version', params: ["", "1.4"], timeout: 20000);
      if (result is List) {
        return result.map((dynamic val) => val.toString()).toList();
      }
    } catch (e) {
      printV("version: timed out or failed: $e");
    }

    return [];
  }

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

  Future<List<Map<String, dynamic>>> getHistory(String scriptHash) async {
    try {
      final result =
          await call(method: 'blockchain.scripthash.get_history', params: [scriptHash]);
      if (result is List) {
        return result.map((dynamic val) {
          if (val is Map<String, dynamic>) {
            return val;
          }

          return <String, dynamic>{};
        }).toList();
      }

      return [];
    } catch (e) {
      // Callers already treat an empty history the same as "couldn't fetch
      // it this round" (see _fetchAddressHistory's failedCount handling) -
      // a timed-out call() (or any other transport error) should degrade
      // the same way, not propagate and abort the whole Future.wait chunk
      // it's part of.
      return [];
    }
  }

  Future<List<Map<String, dynamic>>?> getListUnspent(String scriptHash) async {
    try {
      final result =
          await call(method: 'blockchain.scripthash.listunspent', params: [scriptHash]);

      if (result is List) {
        return result.map((dynamic val) {
          if (val is Map<String, dynamic>) {
            return val;
          }

          return <String, dynamic>{};
        }).toList();
      }

      return null;
    } catch (e) {
      // Same reasoning as getHistory's catch above - null already means
      // "failed to fetch" to every caller (see fetchUnspent's null check),
      // so a timeout should fall into that existing path instead of
      // throwing out of this Future and rejecting the whole chunk it's
      // batched into via Future.wait.
      return null;
    }
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

  Future<Map<String, List<Map<String, dynamic>>>> getBatchHistory(
    List<String> scriptHashes, {
    int timeout = 10000,
  }) async {
    final paramsList = scriptHashes.map((h) => <Object>[h]).toList(growable: false);

    final batchResults = await callBatchWithTimeout(
      method: 'blockchain.scripthash.get_history',
      paramsList: paramsList,
      timeout: timeout,
    );

    final historyMap = <String, List<Map<String, dynamic>>>{};

    for (int i = 0; i < scriptHashes.length; i++) {
      final sh = scriptHashes[i];

      if (i >= batchResults.length) {
        historyMap[sh] = const [];
        continue;
      }

      final result = batchResults[i];

      if (result is List) {
        historyMap[sh] = result
            .whereType<Map<dynamic, dynamic>>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        historyMap[sh] = const [];
      }
    }

    return historyMap;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getBatchUnspent(
    List<String> scriptHashes, {
    int timeout = 10000,
  }) async {
    final paramsList = scriptHashes.map((h) => <Object>[h]).toList(growable: false);

    final batchResults = await callBatchWithTimeout(
      method: 'blockchain.scripthash.listunspent',
      paramsList: paramsList,
      timeout: timeout,
    );

    final unspentMap = <String, List<Map<String, dynamic>>>{};

    for (int i = 0; i < scriptHashes.length; i++) {
      final sh = scriptHashes[i];

      if (i >= batchResults.length) {
        unspentMap[sh] = const [];
        continue;
      }

      final result = batchResults[i];

      if (result is List) {
        unspentMap[sh] = result
            .whereType<Map<dynamic, dynamic>>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        unspentMap[sh] = const [];
      }
    }

    return unspentMap;
  }

  Future<Map<String, Map<String, dynamic>>> getBatchBalance(
    List<String> scriptHashes, {
    int timeout = 10000,
  }) async {
    final paramsList = scriptHashes.map((h) => <Object>[h]).toList(growable: false);

    final batchResults = await callBatchWithTimeout(
      method: 'blockchain.scripthash.get_balance',
      paramsList: paramsList,
      timeout: timeout,
    );

    final balanceMap = <String, Map<String, dynamic>>{};

    for (int i = 0; i < scriptHashes.length; i++) {
      final sh = scriptHashes[i];

      if (i >= batchResults.length) {
        balanceMap[sh] = <String, dynamic>{};
        continue;
      }

      final result = batchResults[i];

      if (result is Map<String, dynamic>) {
        balanceMap[sh] = result;
      } else if (result is Map) {
        balanceMap[sh] = Map<String, dynamic>.from(result);
      } else {
        balanceMap[sh] = <String, dynamic>{};
      }
    }

    return balanceMap;
  }

  Future<Map<String, Map<String, dynamic>>> getBatchTransactionVerbose(
    List<String> hashes, {
    int timeout = 10000,
  }) async {
    final result = <String, Map<String, dynamic>>{};
    if (hashes.isEmpty) return result;

    final paramsList = hashes.map((h) => <Object>[h, true]).toList(growable: false);
    final batchResults = await callBatchWithTimeout(
      method: 'blockchain.transaction.get',
      paramsList: paramsList,
      timeout: timeout,
    );

    for (var i = 0; i < hashes.length; i++) {
      final txid = hashes[i];
      final r = (i < batchResults.length) ? batchResults[i] : null;
      if (r is Map<String, dynamic>) {
        result[txid] = r;
      } else {
        result[txid] = <String, dynamic>{};
      }
    }

    return result;
  }

  Future<Map<String, String?>> getBatchTransactionHex(
    List<String> hashes, {
    int timeout = 10000,
  }) async {
    final result = <String, String?>{};
    if (hashes.isEmpty) return result;

    final paramsList = hashes.map((h) => <Object>[h]).toList(growable: false);
    final batchResults = await callBatchWithTimeout(
      method: 'blockchain.transaction.get',
      paramsList: paramsList,
      timeout: timeout,
    );

    for (var i = 0; i < hashes.length; i++) {
      final txid = hashes[i];
      final r = (i < batchResults.length) ? batchResults[i] : null;
      if (r is String && r.isNotEmpty) {
        result[txid] = r;
      } else {
        result[txid] = null;
      }
    }

    return result;
  }

  Future<List<dynamic>> callBatchWithTimeout({
    required String method,
    required List<List<Object>> paramsList,
    int timeout = 10000,
  }) async {
    if (!isConnected) return [];

    final completer = Completer<List<dynamic>>();
    final int batchBaseId = _id += 1;
    final String internalBatchKey = "batch_$batchBaseId";

    // Build the Batch Array
    final List<Map<String, dynamic>> batchPayload = [];
    for (int i = 0; i < paramsList.length; i++) {
      batchPayload.add(
          {"jsonrpc": "2.0", "method": method, "params": paramsList[i], "id": "$batchBaseId-$i"});
    }

    // Register the task
    _tasks[internalBatchKey] = SocketTask(completer: completer, isSubscription: false);

    // Write to socket
    socket!.write(json.encode(batchPayload) + "\n");

    // Timeout Logic
    Timer(Duration(milliseconds: timeout), () {
      if (!completer.isCompleted) {
        _tasks.remove(internalBatchKey);
        completer.completeError(RequestFailedTimeoutException("BATCH_$method", batchBaseId));
      }
    });

    return completer.future;
  }

  Future<String> broadcastTransaction(
          {required String transactionRaw,
          BasedUtxoNetwork? network,
          Function(int)? idCallback}) async =>
      call(
              method: 'blockchain.transaction.broadcast',
              params: [transactionRaw],
              idCallback: idCallback,
              // A broadcast is rare and high-stakes (unlike the constant
              // routine balance/history polling call()'s default timeout is
              // tuned for), so it deserves real patience under a congested
              // connection rather than surfacing a false-negative timeout
              // while the server may still be about to accept it.
              timeout: 60000)
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

  Future<dynamic> getTweaks({required int height, int timeout = 5000}) async =>
      await callWithTimeout(
          method: 'blockchain.tweaks.subscribe', params: [height, 1, false], timeout: timeout);

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

  // Floor at 0 so unavailable/-1 estimates never become negative rates;
  // cap at 2000 sat/vB per CW-1597.
  static const int _maxFeeRate = 2000;

  static int _sanitizeFeeRate(double feeRate) {
    final rate = (stringDoubleToBitcoinAmount(feeRate.toString()) / 1000).round();
    if (rate < 0) {
      return 0;
    }
    if (rate > _maxFeeRate) {
      return _maxFeeRate;
    }
    return rate;
  }

  Future<List<int>> feeRates({BasedUtxoNetwork? network}) async {
    try {
      final topDouble = await estimatefee(p: 1);
      final middleDouble = await estimatefee(p: 5);
      final bottomDouble = await estimatefee(p: 10);
      final top = _sanitizeFeeRate(topDouble);
      final middle = _sanitizeFeeRate(middleDouble);
      final bottom = _sanitizeFeeRate(bottomDouble);

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

  BehaviorSubject<Object?>? chainTipSubscribe() {
    _id += 1;
    return subscribe<Object?>(
        id: 'blockchain.headers.subscribe', method: 'blockchain.headers.subscribe');
  }

  // Nullable: an address with no transaction history yet has a `null` status
  // per the Electrum protocol spec — completely normal, especially for a
  // wallet with many unused derived addresses. A non-nullable BehaviorSubject
  // here used to throw a TypeError on .add(null) for every such address,
  // which _parseResponse's TypeError handler silently swallowed, so the
  // (harmless-in-content, but real) initial ack was lost every time.
  BehaviorSubject<Object?>? scripthashUpdate(String scripthash) {
    _id += 1;
    return subscribe<Object?>(
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
      // The subscribe request's own initial reply (the current status,
      // returned as a plain {"id":..., "result":...} with no "method") comes
      // back keyed by this numeric wire id, not by the descriptive `id`
      // string registered above — _finish looks replies up by exactly what
      // the server echoes. Without this second registration under the wire
      // id, that first reply could never match anything in _tasks and was
      // being silently dropped for every single subscription (confirmed via
      // "_finish: no pending task" logging). Ongoing push updates after this
      // point carry "method" and are still routed via _methodHandler using
      // the descriptive `id` key, unaffected by this.
      _tasks[_id.toString()] = SocketTask(subject: subscription, isSubscription: true);
      socket!.write(jsonrpc(method: method, id: _id, params: params));

      return subscription;
    } catch (e) {
      printV("subscribe $e");
      return null;
    }
  }

  Future<dynamic> call(
      {required String method,
      List<Object> params = const [],
      Function(int)? idCallback,
      int timeout = 20000}) async {
    if (!isConnected) return null;

    final completer = Completer<dynamic>();
    _id += 1;
    final id = _id;
    idCallback?.call(id);
    _registryTask(id, completer);
    socket!.write(jsonrpc(method: method, id: id, params: params));

    // Without this, a single reply that never arrives (server/proxy drops
    // it, or a reconnect orphans this id) leaves the completer pending
    // forever - and every caller of call() awaits it via Future.wait over a
    // chunk of addresses, so one stuck request wedges the whole chunk, and
    // everything downstream of it, permanently. callWithTimeout already
    // guards against this for its own callers; call() needs the same guard.
    Timer(Duration(milliseconds: timeout), () {
      if (!completer.isCompleted) {
        completer.completeError(RequestFailedTimeoutException(method, id));
      }
    });

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
      // electrs-tweaks never echoes the request id for this method — it
      // replies in push-notification shape (method+params, no id) even for
      // a one-shot query (confirmed directly against the server). Track
      // which pending task issued this specific call so _methodHandler can
      // route the reply correctly instead of guessing via _tasks.keys.first.
      if (method == 'blockchain.tweaks.subscribe') {
        _lastTweaksSubscribeRequestId = id.toString();
      }
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
  }

  void _registryTask(int id, Completer<dynamic> completer) =>
      _tasks[id.toString()] = SocketTask(completer: completer, isSubscription: false);

  void _regisrySubscription(String id, BehaviorSubject<dynamic> subject) =>
      _tasks[id] = SocketTask(subject: subject, isSubscription: true);

  void _finish(String id, Object? data) {
    if (_tasks[id] == null) {
      return;
    }

    // A subscription-type task has no completer (only a subject) — a bare
    // `!.complete()` here would throw a null-check error on it now that
    // subscribe() also registers its wire id through this same path.
    final completer = _tasks[id]?.completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(data);
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
        // Route to the one-shot probe's own tracked request id (see
        // callWithTimeout) instead of guessing via _tasks.keys.first, which
        // only pointed at the right task when it was coincidentally the
        // sole entry in _tasks — never true once anything else (a ping, a
        // subscription, a balance call) was also in flight, silently
        // stranding the real caller to time out instead. _finish (not
        // .subject — this task is a plain completer, not a subscription)
        // completes it and removes it; a second push for the same request
        // (electrs-tweaks can send a data payload then a separate "done"
        // sentinel) finds nothing left and is a harmless no-op.
        final requestId = _lastTweaksSubscribeRequestId;
        if (requestId != null) {
          _finish(requestId, params.last);
        }
        break;
      default:
        break;
    }
  }

  void _setConnectionStatus(ConnectionStatus status) {
    onConnectionStatusChange?.call(status);
    _connectionStatus = status;
    if (!isConnected) {
      try {
        socket?.destroy();
      } catch (_) {}
      socket = null;
    }
  }

  void _handleResponse(dynamic response) {
    // Handle batch response
    if (response is List) {
      if (response.isEmpty) return;

      // Sort responses by ID to ensure correct order for batch processing
      response.sort((a, b) {
        try {
          final idA = int.parse(a['id'].toString().split('-').last);
          final idB = int.parse(b['id'].toString().split('-').last);
          return idA.compareTo(idB);
        } catch (_) {
          return 0;
        }
      });

      final firstRaw = response.first;
      if (firstRaw is! Map) {
        return;
      }
      final firstItem = firstRaw;
      final String firstIdAttr = firstItem['id'].toString();

      final String batchKey = firstIdAttr.contains('-')
          ? "batch_${firstIdAttr.split('-')[0].replaceAll('batch_', '')}"
          : firstIdAttr;

      // Extract the results from each item in the batch
      final results = response.map((item) {
        if (item is Map) {
          return item['result'] ?? item['error'];
        }
        return null;
      }).toList();

      _finish(batchKey, results);
      return;
    }

    // Handle single response
    if (response is Map<String, dynamic>) {
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
  }

  String getErrorMessage(int id) => _errors[id.toString()] ?? '';

  bool get isInternalStateConsistent => _errors.isEmpty;
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
