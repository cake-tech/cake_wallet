import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/script_hash.dart';
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
        _isConnected = false,
        _tasks = {},
        _errors = {},
        unterminatedString = '';

  static const connectionTimeout = Duration(seconds: 5);
  static const aliveTimerDuration = Duration(seconds: 4);

  bool get isConnected => _isConnected;
  Socket? socket;
  void Function(ConnectionStatus)? onConnectionStatusChange;
  int _id;
  final Map<String, SocketTask> _tasks;
  Map<String, SocketTask> get tasks => _tasks;
  final Map<String, String> _errors;
  bool _isConnected;
  Timer? _aliveTimer;
  String unterminatedString;

  Uri? uri;
  bool? useSSL;

  Future<void> connectToUri(Uri uri, {bool? useSSL}) async {
    this.uri = uri;
    this.useSSL = useSSL;
    await connect(host: uri.host, port: uri.port, useSSL: useSSL);
  }

  Future<void> connect({required String host, required int port, bool? useSSL}) async {
    _setConnectionStatus(ConnectionStatus.connecting);

    try {
      await socket?.close();
    } catch (_) {}

    try {
      if (useSSL == false || (useSSL == null && uri.toString().contains("btc-electrum"))) {
        socket = await Socket.connect(host, port, timeout: connectionTimeout);
      } else {
        socket = await SecureSocket.connect(
          host,
          port,
          timeout: connectionTimeout,
          onBadCertificate: (_) => true,
        );
      }
    } catch (_) {
      _setConnectionStatus(ConnectionStatus.failed);
      return;
    }

    if (socket == null) {
      _setConnectionStatus(ConnectionStatus.failed);
      return;
    }
    _setConnectionStatus(ConnectionStatus.connected);

    socket!.listen((Uint8List event) {
      try {
        final msg = utf8.decode(event.toList());
        final messagesList = msg.split("\n");
        for (var message in messagesList) {
          if (message.isEmpty) {
            continue;
          }
          _parseResponse(message);
        }
      } catch (e) {
        print(e.toString());
      }
    }, onError: (Object error) {
      final errorMsg = error.toString();
      print(errorMsg);
      unterminatedString = '';

      final currentHost = socket?.address.host;
      final isErrorForCurrentHost = errorMsg.contains(" ${currentHost} ");

      if (currentHost != null && isErrorForCurrentHost)
        _setConnectionStatus(ConnectionStatus.failed);
    }, onDone: () {
      unterminatedString = '';
      if (host == socket?.address.host) _setConnectionStatus(ConnectionStatus.disconnected);
    });

    keepAlive();
  }

  void _parseResponse(String message) {
    try {
      final response = json.decode(message) as Map<String, dynamic>;
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
      print(e.toString());
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
    } on RequestFailedTimeoutException catch (_) {
      _setConnectionStatus(ConnectionStatus.disconnected);
    }
  }

  Future<List<String>> version() =>
      call(method: 'server.version', params: ["", "1.4"]).then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) => val.toString()).toList();
        }

        return [];
      });

  Future<Map<String, dynamic>> getBalance(String scriptHash) =>
      call(method: 'blockchain.scripthash.get_balance', params: [scriptHash])
          .then((dynamic result) {
        if (result is Map<String, dynamic>) {
          return result;
        }

        return <String, dynamic>{};
      });

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

  Future<List<Map<String, dynamic>>> getListUnspentWithAddress(
          String address, BasedUtxoNetwork network) =>
      call(
          method: 'blockchain.scripthash.listunspent',
          params: [scriptHash(address, network: network)]).then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, dynamic>) {
              val['address'] = address;
              return val;
            }

            return <String, dynamic>{};
          }).toList();
        }

        return [];
      });

  Future<List<Map<String, dynamic>>> getListUnspent(String scriptHash) =>
      call(method: 'blockchain.scripthash.listunspent', params: [scriptHash])
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
      if (result is Map<String, dynamic>) {
        return result;
      }
    } on RequestFailedTimeoutException catch (_) {
      return <String, dynamic>{};
    } catch (e) {
      print("getTransaction: ${e.toString()}");
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
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
    _id += 1;
    return subscribe<Object>(
      id: 'blockchain.tweaks.subscribe:${height + count}',
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
      print("getCurrentBlockChainTip: ${e.toString()}");
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
        _setConnectionStatus(ConnectionStatus.failed);
        return null;
      }
      final subscription = BehaviorSubject<T>();
      _regisrySubscription(id, subscription);
      socket!.write(jsonrpc(method: method, id: _id, params: params));

      return subscription;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<dynamic> call(
      {required String method, List<Object> params = const [], Function(int)? idCallback}) async {
    if (socket == null) {
      _setConnectionStatus(ConnectionStatus.failed);
      return null;
    }
    final completer = Completer<dynamic>();
    _id += 1;
    final id = _id;
    idCallback?.call(id);
    _registryTask(id, completer);
    socket!.write(jsonrpc(method: method, id: id, params: params));

    return completer.future;
  }

  Future<dynamic> callWithTimeout(
      {required String method, List<Object> params = const [], int timeout = 4000}) async {
    try {
      if (socket == null) {
        _setConnectionStatus(ConnectionStatus.failed);
        return null;
      }
      final completer = Completer<dynamic>();
      _id += 1;
      final id = _id;
      _registryTask(id, completer);
      socket!.write(jsonrpc(method: method, id: id, params: params));
      Timer(Duration(milliseconds: timeout), () {
        if (!completer.isCompleted) {
          completer.completeError(RequestFailedTimeoutException(method, id));
        }
      });

      return completer.future;
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> close() async {
    _aliveTimer?.cancel();
    try {
      await socket?.close();
      socket = null;
    } catch (_) {}
    onConnectionStatusChange = null;
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
    onConnectionStatusChange?.call(status);
    _isConnected = status == ConnectionStatus.connected;
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
