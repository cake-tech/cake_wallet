import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_methods.dart';
// import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_params.dart';
import 'package:cw_bitcoin/electrum_worker/methods/methods.dart';

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

  void _sendResponse<T, U>(ElectrumWorkerResponse<T, U> response) {
    sendPort.send(jsonEncode(response.toJson()));
  }

  void _sendError(ElectrumWorkerErrorResponse response) {
    sendPort.send(jsonEncode(response.toJson()));
  }

  void handleMessage(dynamic message) async {
    print("Worker: received message: $message");

    try {
      Map<String, dynamic> messageJson;
      if (message is String) {
        messageJson = jsonDecode(message) as Map<String, dynamic>;
      } else {
        messageJson = message as Map<String, dynamic>;
      }
      final workerMethod = messageJson['method'] as String;

      switch (workerMethod) {
        case ElectrumWorkerMethods.connectionMethod:
          await _handleConnect(
            ElectrumWorkerConnectionRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.headersSubscribeMethod:
          await _handleHeadersSubscribe();
          break;
        case ElectrumRequestMethods.scripthashesSubscribeMethod:
          await _handleScriphashesSubscribe(
            ElectrumWorkerScripthashesSubscribeRequest.fromJson(messageJson),
          );
          break;
        // case 'blockchain.scripthash.get_balance':
        //   await _handleGetBalance(message);
        //   break;
        case 'blockchain.scripthash.get_history':
          // await _handleGetHistory(workerMessage);
          break;
        case 'blockchain.scripthash.listunspent':
          // await _handleListUnspent(workerMessage);
          break;
        // Add other method handlers here
        // default:
        //   _sendError(workerMethod, 'Unsupported method: ${workerMessage.method}');
      }
    } catch (e, s) {
      print(s);
      _sendError(ElectrumWorkerErrorResponse(error: e.toString()));
    }
  }

  Future<void> _handleConnect(ElectrumWorkerConnectionRequest request) async {
    _electrumClient = ElectrumApiProvider(
      await ElectrumTCPService.connect(
        request.uri,
        onConnectionStatusChange: (status) {
          _sendResponse(ElectrumWorkerConnectionResponse(status: status));
        },
        defaultRequestTimeOut: const Duration(seconds: 5),
        connectionTimeOut: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleHeadersSubscribe() async {
    final listener = _electrumClient!.subscribe(ElectrumHeaderSubscribe());
    if (listener == null) {
      _sendError(ElectrumWorkerHeadersSubscribeError(error: 'Failed to subscribe'));
      return;
    }

    listener((event) {
      _sendResponse(ElectrumWorkerHeadersSubscribeResponse(result: event));
    });
  }

  Future<void> _handleScriphashesSubscribe(
    ElectrumWorkerScripthashesSubscribeRequest request,
  ) async {
    await Future.wait(request.scripthashByAddress.entries.map((entry) async {
      final address = entry.key;
      final scripthash = entry.value;
      final listener = await _electrumClient!.subscribe(
        ElectrumScriptHashSubscribe(scriptHash: scripthash),
      );

      if (listener == null) {
        _sendError(ElectrumWorkerScripthashesSubscribeError(error: 'Failed to subscribe'));
        return;
      }

      // https://electrumx.readthedocs.io/en/latest/protocol-basics.html#status
      // The status of the script hash is the hash of the tx history, or null if the string is empty because there are no transactions
      listener((status) async {
        print("status: $status");

        _sendResponse(ElectrumWorkerScripthashesSubscribeResponse(
          result: {address: status},
        ));
      });
    }));
  }

  // Future<void> _handleGetBalance(ElectrumWorkerRequest message) async {
  //   try {
  //     final scriptHash = message.params['scriptHash'] as String;
  //     final result = await _electrumClient!.request(
  //       ElectrumGetScriptHashBalance(scriptHash: scriptHash),
  //     );

  //     final balance = ElectrumBalance(
  //       confirmed: result['confirmed'] as int? ?? 0,
  //       unconfirmed: result['unconfirmed'] as int? ?? 0,
  //       frozen: 0,
  //     );

  //     _sendResponse(message.method, balance.toJSON());
  //   } catch (e, s) {
  //     print(s);
  //     _sendError(message.method, e.toString());
  //   }
  // }

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
