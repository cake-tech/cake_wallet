import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;

String jsonrpcparams(List<Object> params) {
  final _params = params?.map((val) => '"${val.toString()}"')?.join(',');
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
        unterminatedString = '';

  static const connectionTimeout = Duration(seconds: 5);
  static const aliveTimerDuration = Duration(seconds: 4);

  bool get isConnected => _isConnected;
  Socket? socket;
  void Function(bool)? onConnectionStatusChange;
  int _id;
  final Map<String, SocketTask> _tasks;
  bool _isConnected;
  Timer? _aliveTimer;
  String unterminatedString;

  Future<void> connectToUri(Uri uri) async => await connect(host: uri.host, port: uri.port);

  Future<void> connect({required String host, required int port}) async {
    try {
      await socket?.close();
    } catch (_) {}

    socket = await SecureSocket.connect(host, port,
        timeout: connectionTimeout, onBadCertificate: (_) => true);
    _setIsConnected(true);

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
      print(error.toString());
      unterminatedString = '';
      _setIsConnected(false);
    }, onDone: () {
      unterminatedString = '';
      _setIsConnected(false);
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
      _setIsConnected(true);
    } on RequestFailedTimeoutException catch (_) {
      _setIsConnected(false);
    }
  }

  Future<List<String>> version() => call(method: 'server.version').then((dynamic result) {
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

  Future<Map<String, dynamic>> getTransactionRaw({required String hash}) async =>
      callWithTimeout(method: 'blockchain.transaction.get', params: [hash, true], timeout: 10000)
          .then((dynamic result) {
        if (result is Map<String, dynamic>) {
          return result;
        }

        return <String, dynamic>{};
      });

  Future<String> getTransactionHex({required String hash}) async =>
      callWithTimeout(method: 'blockchain.transaction.get', params: [hash, false], timeout: 10000)
          .then((dynamic result) {
        if (result is String) {
          return result;
        }

        return '';
      });

  Future<String> broadcastTransaction(
      {required String transactionRaw, BasedUtxoNetwork? network}) async {
    if (network == BitcoinNetwork.testnet) {
      return http
          .post(Uri(scheme: 'https', host: 'blockstream.info', path: '/testnet/api/tx'),
              headers: <String, String>{'Content-Type': 'application/json; charset=utf-8'},
              body: transactionRaw)
          .then((http.Response response) {
        if (response.statusCode == 200) {
          return response.body;
        }

        throw Exception('Failed to broadcast transaction: ${response.body}');
      });
    }

    return call(method: 'blockchain.transaction.broadcast', params: [transactionRaw])
        .then((dynamic result) {
      if (result is String) {
        return result;
      }

      return '';
    });
  }

  Future<Map<String, dynamic>> getMerkle({required String hash, required int height}) async =>
      await call(method: 'blockchain.transaction.get_merkle', params: [hash, height])
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getHeader({required int height}) async =>
      await call(method: 'blockchain.block.get_header', params: [height]) as Map<String, dynamic>;

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
    if (network == BitcoinNetwork.testnet) {
      return [1, 1, 1];
    }
    try {
      final topDoubleString = await estimatefee(p: 1);
      final middleDoubleString = await estimatefee(p: 5);
      final bottomDoubleString = await estimatefee(p: 100);
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
  Future<int?> getCurrentBlockChainTip() =>
      call(method: 'blockchain.headers.subscribe').then((result) {
        if (result is Map<String, dynamic>) {
          return result["height"] as int;
        }

        return null;
      });

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
      final subscription = BehaviorSubject<T>();
      _regisrySubscription(id, subscription);
      socket!.write(jsonrpc(method: method, id: _id, params: params));

      return subscription;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<dynamic> call({required String method, List<Object> params = const []}) async {
    final completer = Completer<dynamic>();
    _id += 1;
    final id = _id;
    _registryTask(id, completer);
    socket!.write(jsonrpc(method: method, id: id, params: params));

    return completer.future;
  }

  Future<dynamic> callWithTimeout(
      {required String method, List<Object> params = const [], int timeout = 4000}) async {
    try {
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
    await socket?.close();
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
      default:
        break;
    }
  }

  void _setIsConnected(bool isConnected) {
    if (_isConnected != isConnected) {
      onConnectionStatusChange?.call(isConnected);
    }

    _isConnected = isConnected;
  }

  void _handleResponse(Map<String, dynamic> response) {
    final method = response['method'];
    final id = response['id'] as String?;
    final result = response['result'];

    if (method is String) {
      _methodHandler(method: method, request: response);
      return;
    }

    if (id != null) {
      _finish(id, result);
    }
  }
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
