import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:cw_bitcoin/payjoin/manager.dart';
import 'package:cw_bitcoin/payjoin/payjoin_session_errors.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/send.dart';
import 'package:payjoin_flutter/src/generated/frb_generated.dart' as pj;
import 'package:payjoin_flutter/src/generated/api/send/error.dart' as pj_error;
import 'package:payjoin_flutter/uri.dart' as pj_uri;

enum PayjoinSenderRequestTypes {
  requestPosted,
  psbtToSign;
}

class PayjoinSenderWorker {
  final SendPort sendPort;
  final pendingRequests = <String, Completer<dynamic>>{};
  final String pjUrl;

  PayjoinSenderWorker._(this.sendPort, this.pjUrl);

  static Future<void> run(List<Object> args) async {
    await pj.core.init();

    final sendPort = args[0] as SendPort;
    final senderJson = args[1] as String;
    final pjUrl = args[2] as String;

    final sender = Sender.fromJson(json: senderJson);
    final worker = PayjoinSenderWorker._(sendPort, pjUrl);

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
  final client = ProxyWrapper().getHttpIOClient();

  /// Run a payjoin sender (V2 protocol first, fallback to V1).
  Future<String> runSender(Sender sender) async {

    try {
      return await _runSenderV2(sender);
    } catch (e) {
      printV(e);
      if (e is pj_error.FfiCreateRequestError) {
        return await _runSenderV1(sender);
      } else if (e is HttpException) {
        printV(e);
        throw Exception(PayjoinSessionError.recoverable(e.toString()));
      } else {
        throw Exception(PayjoinSessionError.unrecoverable(e.toString()));
      }
    }
  }

  /// Attempt to send payjoin using the V2 of the protocol.
  Future<String> _runSenderV2(Sender sender) async {
    try {
      final postRequest = await sender.extractV2(
        ohttpProxyUrl:
            await pj_uri.Url.fromStr(PayjoinManager.randomOhttpRelayUrl()),
      );

      final postResult = await _postRequest(postRequest.$1);
      final getContext =
      await postRequest.$2.processResponse(response: postResult);

      sendPort.send({'type': PayjoinSenderRequestTypes.requestPosted, "pj": pjUrl});

      while (true) {
        printV('Polling V2 Proposal Request (${pjUrl})');

        final getRequest = await getContext.extractReq(
          ohttpRelay: await PayjoinManager.randomOhttpRelayUrl(),
        );
        final getRes = await _postRequest(getRequest.$1);
        final proposalPsbt = await getContext.processResponse(
          response: getRes,
          ohttpCtx: getRequest.$2,
        );
        printV("$proposalPsbt");
        if (proposalPsbt != null) return proposalPsbt;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Attempt to send payjoin using the V1 of the protocol.
  Future<String> _runSenderV1(Sender sender) async {
    try {
      final postRequest = await sender.extractV1();
      final response = await _postRequest(postRequest.$1);

      sendPort.send({'type': PayjoinSenderRequestTypes.requestPosted});

      return await postRequest.$2.processResponse(response: response);
    } catch (e, stack) {
      throw PayjoinSessionError.unrecoverable('Send V1 payjoin error: $e, $stack');
    }
  }

  Future<List<int>> _postRequest(Request req) async {
    final httpRequest = await client.post(Uri.parse(req.url.asString()),
        headers: {'Content-Type': req.contentType}, body: req.body);

    return httpRequest.bodyBytes;
  }
}
