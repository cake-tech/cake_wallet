import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/payjoin/payjoin_worker.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_bitcoin/psbt_signer.dart';
import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/receive.dart';
import 'package:payjoin_flutter/uri.dart';

class PayjoinManager {
  PayjoinManager(this._payjoinStorage, this._wallet);

  final PayjoinStorage _payjoinStorage;
  final BitcoinWalletBase _wallet;
  final Map<String, PayjoinPollerSession> _activePollers = {};

  static const List<String> _ohttpRelayUrls = [
    'https://pj.bobspacebkk.com',
    'https://ohttp.achow101.com',
  ];

  static const payjoinDirectoryUrl = 'https://payjo.in';

  Future<Receiver> initReceiver(String address,
      [bool isTestnet = false]) async {
    try {
      final payjoinDirectory = await Url.fromStr(payjoinDirectoryUrl);

      final ohttpKeys = await fetchOhttpKeys(
        ohttpRelay: await _randomOhttpRelayUrl(),
        payjoinDirectory: payjoinDirectory,
      );

      return Receiver.create(
        address: address,
        network: isTestnet ? Network.testnet : Network.bitcoin,
        directory: payjoinDirectory,
        ohttpKeys: ohttpKeys,
        ohttpRelay: await _randomOhttpRelayUrl(),
      );
    } catch (e) {
      throw Exception('Error initializing payjoin Receiver: $e');
    }
  }

  Future<void> spawnNewReceiver({
    required Receiver receiver,
    bool isTestnet = false,
  }) async {
    await _payjoinStorage.insertReceiverSession(
      receiver,
      _wallet.id,
    );
    return spawnReceiver(
      isTestnet: isTestnet,
      receiver: receiver,
    );
  }

  Future<void> spawnReceiver({
    required Receiver receiver,
    bool isTestnet = false,
  }) async {
    final completer = Completer();
    final receivePort = ReceivePort();

    SendPort? mainToIsolateSendPort;
    List<UtxoWithPrivateKey> utxos = [];

    receivePort.listen((message) async {
      print('Receiver isolate: $message');
      if (message is Map<String, dynamic>) {
        try {
          switch (message['type']) {
            case PayjoinReceiverRequestTypes.checkIsOwned:
              final inputScript = message['input_script'] as Uint8List;
              final isOwned =
                  _wallet.isMine(Script.fromRaw(byteData: inputScript));
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': isOwned,
              });
              break;

            case PayjoinReceiverRequestTypes.checkIsReceiverOutput:
              final outputScript = message['output_script'] as Uint8List;
              final isReceiverOutput =
                  _wallet.isMine(Script.fromRaw(byteData: outputScript));
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': isReceiverOutput,
              });
              break;

            case PayjoinReceiverRequestTypes.getCandidateInputs:
              utxos = _wallet.getUtxoWithPrivateKeys();
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': utxos,
              });
              break;

            case PayjoinReceiverRequestTypes.processPsbt:
              final psbt = message['psbt'] as String;
              final signedPsbt = await _wallet.signPsbt(psbt, utxos);
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': signedPsbt,
              });
              break;

            case PayjoinReceiverRequestTypes.proposalSent:
              await _cleanupSession(receiver.id());
              await _payjoinStorage.markReceiverSessionComplete(receiver.id());
              completer.complete();
          }
        } catch (e) {
          await _cleanupSession(receiver.id());
          await _payjoinStorage.markReceiverSessionUnrecoverable(receiver.id());
          completer.completeError(e);
        }
      } else if (message is PayjoinSessionError) {
        await _cleanupSession(receiver.id());
        if (message is UnrecoverableError) {
          await _payjoinStorage.markReceiverSessionUnrecoverable(receiver.id());
        }
        completer.completeError(message);
      } else if (message is SendPort) {
        mainToIsolateSendPort = message;
      }
    });

    final args = [
      receivePort.sendPort,
      receiver.toJson(),
    ];

    final isolate = await Isolate.spawn(
      PayjoinReceiverWorker.run,
      args,
    );

    _activePollers[receiver.id()] = PayjoinPollerSession(isolate, receivePort);

    return completer.future;
  }


  Future<void> _cleanupSession(String sessionId) async {
    _activePollers[sessionId]?.close();
    _activePollers.remove(sessionId);
  }

  // Top-level function to generate random OHTTP relay URL
  Future<Url> _randomOhttpRelayUrl() => Url.fromStr(
        _ohttpRelayUrls[Random.secure().nextInt(_ohttpRelayUrls.length)],
      );
}

class PayjoinPollerSession {
  final Isolate isolate;
  final ReceivePort port;

  PayjoinPollerSession(this.isolate, this.port);

  void close() {
    isolate.kill();
    port.close();
  }
}
