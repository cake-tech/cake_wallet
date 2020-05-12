import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

String jsonrpcparams(List<Object> params) {
  final _params = params?.map((val) => '"${val.toString()}"')?.join(',');
  return "[$_params]";
}

String jsonrpc(
        {String method, List<Object> params, int id, double version = 2.0}) =>
    '{"jsonrpc": "$version", "method": "$method", "id": "$id",  "params": ${jsonrpcparams(params)}}\n';

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
  int _id;
  final Map<String, SocketTask> _tasks;
  bool _isConnected;

  Future<void> connect({@required String host, @required int port}) async {
    if (socket != null) {
      await socket.close();
    }

    final start = DateTime.now();

    socket = await SecureSocket.connect(host, port, timeout: connectionTimeout);

    _isConnected = true;

    socket.listen((List<int> event) {
      try {
        final Map<String, Object> jsoned =
            json.decode(utf8.decode(event)) as Map<String, Object>;
        final method = jsoned['method'];

        if (method is String) {
          _methodHandler(method: method, request: jsoned);
          return;
        }

        final id = jsoned['id'] as String;
        final params = jsoned['result'];

        _finish(id, params);
      } catch (e) {
        print(e);
      }
    }, onError: (Object error) {
      print('ElectrumClient error: ${error.toString()}');
    }, onDone: () {
      final end = DateTime.now();
      final diff = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      print('On done: $diff');
    });

    print('Connected to ${socket.remoteAddress}');
  }

  Future<void> ping() => call(method: 'server.ping');

  Future<List<String>> version() =>
      call(method: 'server.version').then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) => val.toString()).toList();
        }

        return [];
      });

  Future<Map<String, Object>> getBalance({String address}) =>
      call(method: 'blockchain.address.get_balance', params: [address])
          .then((dynamic result) {
        if (result is Map<String, Object>) {
          return result;
        }

        return Map<String, Object>();
      });

  Future<List<Map<String, dynamic>>> getHistory({String address}) =>
      call(method: 'blockchain.address.get_history', params: [address])
          .then((dynamic result) {
        if (result is List) {
          return result.map((dynamic val) {
            if (val is Map<String, Object>) {
              return val;
            }

            return Map<String, Object>();
          }).toList();
        }

        return [];
      });

  Future<String> getTransactionRaw({@required String hash}) async =>
      call(method: 'blockchain.transaction.get', params: [hash])
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

  BehaviorSubject<Object> addressUpdate({@required String address}) =>
      subscribe<Object>(
          id: 'blockchain.address.subscribe:$address',
          method: 'blockchain.address.subscribe',
          params: [address]);

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

    _tasks[id]?.completer?.complete(data);

    if (!(_tasks[id]?.isSubscription ?? false)) {
      _tasks[id] = null;
    } else {
      _tasks[id].subject.add(data);
    }
  }

  void _methodHandler(
      {@required String method, @required Map<String, Object> request}) {
    switch (method) {
      case 'blockchain.address.subscribe':
        final params = request['params'] as List<dynamic>;
        final address = params.first as String;
        final id = 'blockchain.address.subscribe:$address';

        if (_tasks[id] != null) {
          _tasks[id].subject.add(params.last);
        }

        break;
      default:
        break;
    }
  }
}
