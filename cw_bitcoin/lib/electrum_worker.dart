import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum_balance.dart';

class ElectrumWorkerMessage {
  final String method;
  final Map<String, dynamic> params;

  ElectrumWorkerMessage({
    required this.method,
    required this.params,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'params': params,
      };

  factory ElectrumWorkerMessage.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerMessage(
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>,
    );
  }
}

class ElectrumWorkerResponse {
  final String method;
  final dynamic data;
  final String? error;

  ElectrumWorkerResponse({
    required this.method,
    required this.data,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'data': data,
        'error': error,
      };

  factory ElectrumWorkerResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerResponse(
      method: json['method'] as String,
      data: json['data'],
      error: json['error'] as String?,
    );
  }
}

class ElectrumWorker {
  final SendPort sendPort;
  ElectrumApiProvider? _electrumClient;

  ElectrumWorker._(this.sendPort, {ElectrumApiProvider? electrumClient})
      : _electrumClient = electrumClient;

  static void run(SendPort sendPort) {
    final worker = ElectrumWorker._(sendPort);
    final receivePort = ReceivePort();

    sendPort.send(receivePort.sendPort);

    receivePort.listen(worker.handleMessage);
  }

  Future<void> _handleConnect({
    required Uri uri,
  }) async {
    _electrumClient = ElectrumApiProvider(
      await ElectrumTCPService.connect(
        uri,
        onConnectionStatusChange: (status) {
          _sendResponse('connectionStatus', status.toString());
        },
        defaultRequestTimeOut: const Duration(seconds: 5),
        connectionTimeOut: const Duration(seconds: 5),
      ),
    );
  }

  void handleMessage(dynamic message) async {
    try {
      final workerMessage = ElectrumWorkerMessage.fromJson(message as Map<String, dynamic>);

      switch (workerMessage.method) {
        case 'connect':
          final uri = Uri.parse(workerMessage.params['uri'] as String);
          await _handleConnect(uri: uri);
          break;
        case 'blockchain.scripthash.get_balance':
          await _handleGetBalance(workerMessage);
          break;
        case 'blockchain.scripthash.get_history':
          // await _handleGetHistory(workerMessage);
          break;
        case 'blockchain.scripthash.listunspent':
          // await _handleListUnspent(workerMessage);
          break;
        // Add other method handlers here
        default:
          _sendError(workerMessage.method, 'Unsupported method: ${workerMessage.method}');
      }
    } catch (e, s) {
      print(s);
      _sendError('unknown', e.toString());
    }
  }

  void _sendResponse(String method, dynamic data) {
    final response = ElectrumWorkerResponse(
      method: method,
      data: data,
    );
    sendPort.send(jsonEncode(response.toJson()));
  }

  void _sendError(String method, String error) {
    final response = ElectrumWorkerResponse(
      method: method,
      data: null,
      error: error,
    );
    sendPort.send(jsonEncode(response.toJson()));
  }

  Future<void> _handleGetBalance(ElectrumWorkerMessage message) async {
    try {
      final scriptHash = message.params['scriptHash'] as String;
      final result = await _electrumClient!.request(
        ElectrumGetScriptHashBalance(scriptHash: scriptHash),
      );

      final balance = ElectrumBalance(
        confirmed: result['confirmed'] as int? ?? 0,
        unconfirmed: result['unconfirmed'] as int? ?? 0,
        frozen: 0,
      );

      _sendResponse(message.method, balance.toJSON());
    } catch (e, s) {
      print(s);
      _sendError(message.method, e.toString());
    }
  }

  // Future<void> _handleGetHistory(ElectrumWorkerMessage message) async {
  //   try {
  //     final scriptHash = message.params['scriptHash'] as String;
  //     final result = await electrumClient.getHistory(scriptHash);
  //     _sendResponse(message.method, jsonEncode(result));
  //   } catch (e) {
  //     _sendError(message.method, e.toString());
  //   }
  // }

  // Future<void> _handleListUnspent(ElectrumWorkerMessage message) async {
  //   try {
  //     final scriptHash = message.params['scriptHash'] as String;
  //     final result = await electrumClient.listUnspent(scriptHash);
  //     _sendResponse(message.method, jsonEncode(result));
  //   } catch (e) {
  //     _sendError(message.method, e.toString());
  //   }
  // }
}
