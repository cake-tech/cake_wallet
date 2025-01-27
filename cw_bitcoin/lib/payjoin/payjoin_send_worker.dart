import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:cw_bitcoin/payjoin/manager.dart';
import 'package:cw_bitcoin/payjoin/payjoin_session_errors.dart';
import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/send.dart';
import 'package:payjoin_flutter/src/generated/frb_generated.dart' as pj;

enum PayjoinSenderRequestTypes {
  requestPosted,
  psbtToSign;
}

class PayjoinSenderWorker {
  final SendPort sendPort;
  final pendingRequests = <String, Completer<dynamic>>{};

  PayjoinSenderWorker._(this.sendPort);

  static Future<void> run(List<Object> args) async {
    await pj.core.init();

    final sendPort = args[0] as SendPort;
    final senderJson = args[1] as String;

    final sender = Sender.fromJson(senderJson);
    final worker = PayjoinSenderWorker._(sendPort);

    try {
      final proposalPsbt = await worker.runSender(sender);
      sendPort.send({
        'type': PayjoinSenderRequestTypes.psbtToSign,
        'psbt': proposalPsbt,
      });
    } catch (e) {
      sendPort.send(e);
    }
  }

  /// Run a payjoin sender (V2 protocol first, fallback to V1).
  Future<String> runSender(Sender sender) async {
    final httpClient = HttpClient();

    try {
      return await _runSenderV2(sender, httpClient);
    } catch (e) {
      if (e is PayjoinException &&
          // TODO condition on error type instead of message content
          e.message?.contains('parse receiver public key') == true) {
        return await _runSenderV1(sender, httpClient);
      } else if (e is HttpException) {
        throw Exception(PayjoinSessionError.recoverable(e.toString()));
      } else {
        throw Exception(PayjoinSessionError.unrecoverable(e.toString()));
      }
    }
  }

  /// Attempt to send payjoin using the V2 of the protocol.
  Future<String> _runSenderV2(Sender sender, HttpClient httpClient) async {
    final postRequest = await sender.extractV2(
      ohttpProxyUrl: await await PayjoinManager.randomOhttpRelayUrl(),
    );

    final postResult = await _postRequest(httpClient, postRequest.$1);
    final getContext =
        await postRequest.$2.processResponse(response: postResult);

    sendPort.send({'type': PayjoinSenderRequestTypes.requestPosted});

    while (true) {
      final getRequest = await getContext.extractReq(
        ohttpRelay: await PayjoinManager.randomOhttpRelayUrl(),
      );
      final getRes = await _postRequest(httpClient, getRequest.$1);
      final proposalPsbt = await getContext.processResponse(
        response: getRes,
        ohttpCtx: getRequest.$2,
      );
      if (proposalPsbt != null) return proposalPsbt;
    }
  }

  /// Attempt to send payjoin using the V1 of the protocol.
  Future<String> _runSenderV1(Sender sender, HttpClient httpClient) async {
    try {
      final postRequest = await sender.extractV1();
      final response = await _postRequest(httpClient, postRequest.$1);

      sendPort.send({'type': PayjoinSenderRequestTypes.requestPosted});

      return await postRequest.$2.processResponse(response: response);
    } catch (e) {
      throw PayjoinSessionError.unrecoverable('Send V1 payjoin error: $e');
    }
  }

  Future<List<int>> _postRequest(HttpClient client, Request req) async {
    final httpRequest = await client.postUrl(Uri.parse(req.url.asString()));
    httpRequest.headers.set('Content-Type', req.contentType);
    httpRequest.add(req.body);

    final response = await httpRequest.close();
    return response.fold<List<int>>(
      [],
      (previous, element) => previous..addAll(element),
    );
  }
}
