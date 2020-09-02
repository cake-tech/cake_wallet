import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cake_wallet/bitcoin/script_hash.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

String jsonrpcparams(List<Object> params) {
  final _params = params?.map((val) => '"${val.toString()}"')?.join(',');
  return '[$_params]';
}

String jsonrpc(
        {String method, List<Object> params, int id, double version = 2.0}) =>
    '{"jsonrpc": "$version", "method": "$method", "id": "$id",  "params": ${json.encode(params)}}\n';

class SocketTask {
  SocketTask({this.completer, this.isSubscription, this.subject});

  final Completer completer;
  final BehaviorSubject subject;
  final bool isSubscription;
}

class ElectrumClient {
  ElectrumClient()
      : _id = 0,
        _isConnected = false,
        _tasks = {};

  static const connectionTimeout = Duration(seconds: 5);

  bool get isConnected => _isConnected;
  Socket socket;
  void Function(bool) onConnectionStatusChange;
  int _id;
  final Map<String, SocketTask> _tasks;
  bool _isConnected;
  Timer _aliveTimer;

  Future<void> connectToUri(String uri) async {
    final _uri = Uri.parse(uri);
    final host = _uri.scheme;
    final port = int.parse(_uri.path);
    await connect(host: host, port: port);
  }

  Future<void> connect({@required String host, @required int port}) async {
    try {
      await socket?.close();
    } catch (_) {}

    socket = await SecureSocket.connect(host, port, timeout: connectionTimeout);
    _setIsConnected(true);

    socket.listen((Uint8List event) {
      try {
        final jsoned =
            json.decode(utf8.decode(event.toList())) as Map<String, Object>;
        print(jsoned);
        final method = jsoned['method'];
        final id = jsoned['id'] as String;
        final params = jsoned['result'];

        if (method is String) {
          _methodHandler(method: method, request: jsoned);
          return;
        }

        _finish(id, params);
      } catch (e) {
        print(e);
      }
    }, onError: (Object error) {
      print(error.toString());
      _setIsConnected(false);
    }, onDone: () => _setIsConnected(false));
    keepAlive();
  }

  void keepAlive() {
    _aliveTimer?.cancel();
    // FIXME: Unnamed constant.
    _aliveTimer = Timer.periodic(Duration(seconds: 2), (_) async => ping());
  }

  Future<void> ping() async {
    try {
      await callWithTimeout(method: 'server.ping');
      _setIsConnected(true);
    } on RequestFailedTimeoutException catch (_) {
      _setIsConnected(false);
    }
  }

  Future<List<String>> version() =>
      call(method: 'server.version').then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) => val.toString()).toList();
        }

        return [];
      });

  Future<Map<String, Object>> getBalance(String scriptHash) =>
      call(method: 'blockchain.scripthash.get_balance', params: [scriptHash])
          .then((dynamic result) {
        if (result is Map<String, Object>) {
          return result;
        }

        return <String, Object>{};
      });

  Future<List<Map<String, dynamic>>> getHistory(String scriptHash) =>
      call(method: 'blockchain.scripthash.get_history', params: [scriptHash])
          .then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, Object>) {
              return val;
            }

            return <String, Object>{};
          }).toList();
        }

        return [];
      });

  Future<List<Map<String, dynamic>>> getListUnspentWithAddress(
          String address) =>
      call(
          method: 'blockchain.scripthash.listunspent',
          params: [scriptHash(address)]).then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, Object>) {
              val['address'] = address;
              return val;
            }

            return <String, Object>{};
          }).toList();
        }

        return [];
      });

  Future<List<Map<String, dynamic>>> getListUnspent(String scriptHash) =>
      call(method: 'blockchain.scripthash.listunspent', params: [scriptHash])
          .then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, Object>) {
              return val;
            }

            return <String, Object>{};
          }).toList();
        }

        return [];
      });

  Future<List<Map<String, dynamic>>> getMempool(String scriptHash) =>
      call(method: 'blockchain.scripthash.get_mempool', params: [scriptHash])
          .then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, Object>) {
              return val;
            }

            return <String, Object>{};
          }).toList();
        }

        return [];
      });

  Future<Map<String, Object>> getTransactionRaw(
          {@required String hash}) async =>
      call(method: 'blockchain.transaction.get', params: [hash, true])
          .then((dynamic result) {
        if (result is Map<String, Object>) {
          return result;
        }

        return <String, Object>{};
      });

  Future<Map<String, Object>> getTransactionExpanded(
      {@required String hash}) async {
    final originalTx = await getTransactionRaw(hash: hash);
    final vins = originalTx['vin'] as List<Object>;

    for (dynamic vin in vins) {
      if (vin is Map<String, Object>) {
        vin['tx'] = await getTransactionRaw(hash: vin['txid'] as String);
      }
    }

    return originalTx;
  }

  Future<String> broadcastTransaction(
          {@required String transactionRaw}) async =>
      call(method: 'blockchain.transaction.broadcast', params: [transactionRaw])
          .then((dynamic result) {
        if (result is String) {
          return result;
        }

        return '';
      });

  Future<Map<String, dynamic>> getMerkle(
          {@required String hash, @required int height}) async =>
      await call(
          method: 'blockchain.transaction.get_merkle',
          params: [hash, height]) as Map<String, dynamic>;

  Future<Map<String, dynamic>> getHeader({@required int height}) async =>
      await call(method: 'blockchain.block.get_header', params: [height])
          as Map<String, dynamic>;

  Future<double> estimatefee({@required int p}) =>
      call(method: 'blockchain.estimatefee', params: [p])
          .then((dynamic result) {
        if (result is double) {
          return result;
        }

        if (result is String) {
          return double.parse(result);
        }

        return 0;
      });

  BehaviorSubject<Object> scripthashUpdate(String scripthash) =>
      subscribe<Object>(
          id: 'blockchain.scripthash.subscribe:$scripthash',
          method: 'blockchain.scripthash.subscribe',
          params: [scripthash]);

  BehaviorSubject<T> subscribe<T>(
      {@required String id,
      @required String method,
      List<Object> params = const []}) {
    final subscription = BehaviorSubject<T>();
    _regisrySubscription(id, subscription);
    socket.write(jsonrpc(method: method, id: _id, params: params));

    return subscription;
  }

  Future<dynamic> call({String method, List<Object> params = const []}) {
    final completer = Completer<dynamic>();
    _id += 1;
    final id = _id;
    _regisryTask(id, completer);
    socket.write(jsonrpc(method: method, id: _id, params: params));

    return completer.future;
  }

  Future<dynamic> callWithTimeout(
      {String method,
      List<Object> params = const [],
      int timeout = 2000}) async {
    final completer = Completer<dynamic>();
    _id += 1;
    final id = _id;
    _regisryTask(id, completer);
    socket.write(jsonrpc(method: method, id: _id, params: params));

    Timer(Duration(milliseconds: timeout), () {
      if (!completer.isCompleted) {
        completer.completeError(RequestFailedTimeoutException(method, _id));
      }
    });

    return completer.future;
  }

  void request({String method, List<Object> params = const []}) {
    _id += 1;
    socket.write(jsonrpc(method: method, id: _id, params: params));
  }

  void _regisryTask(int id, Completer completer) => _tasks[id.toString()] =
      SocketTask(completer: completer, isSubscription: false);

  void _regisrySubscription(String id, BehaviorSubject subject) =>
      _tasks[id] = SocketTask(subject: subject, isSubscription: true);

  void _finish(String id, Object data) {
    if (_tasks[id] == null) {
      return;
    }

    if (!(_tasks[id]?.completer?.isCompleted ?? false)) {
      _tasks[id]?.completer?.complete(data);
    }

    if (!(_tasks[id]?.isSubscription ?? false)) {
      _tasks[id] = null;
    } else {
      _tasks[id].subject.add(data);
    }
  }

  void _methodHandler(
      {@required String method, @required Map<String, Object> request}) {
    switch (method) {
      case 'blockchain.scripthash.subscribe':
        final params = request['params'] as List<dynamic>;
        final scripthash = params.first as String;
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
}

class RequestFailedTimeoutException implements Exception {
  RequestFailedTimeoutException(this.method, this.id);

  final String method;
  final int id;
}
