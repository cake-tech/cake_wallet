import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:payjoin/payjoin.dart' as pj;

class PayjoinSenderWorker {
  final http.Client client = ProxyWrapper().getHttpIOClient();
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<String> run(
    String psbtBase64,
    String pjUriString,
    String ohttpRelay,
    int minFeeRateSatPerKwu,
  ) async {
    final pjUri = pj.Uri.parse(uri: pjUriString).checkPjSupported();
    final builder = pj.SenderBuilder(psbt: psbtBase64, uri: pjUri);
    final initialTransition = builder.buildRecommended(
      minFeeRateSatPerKwu: minFeeRateSatPerKwu,
    );
    final persister = _InMemorySenderPersister();
    final withReplyKey = initialTransition.save(persister: persister);

    final subscribeReqCtx = withReplyKey.createV2PostRequest(ohttpRelay: ohttpRelay);
    printV('[pjSender] POST subscribe -> ${subscribeReqCtx.request.url}');
    final subscribeResponse = await _httpPost(subscribeReqCtx.request);

    final withReplyKeyTransition = withReplyKey.processResponse(
      response: subscribeResponse,
      postCtx: subscribeReqCtx.ohttpCtx,
    );
    var polling = withReplyKeyTransition.save(persister: persister);
    printV('[pjSender] subscribe response OK; now polling');

    while (true) {
      if (_cancelled) throw PayjoinSenderCancelledException();
      printV('Polling Payjoin Sender Proposal');
      try {
        final pollReqCtx = polling.createPollRequest(ohttpRelay: ohttpRelay);
        final pollResponse = await _httpPost(pollReqCtx.request);
        final pollTransition = polling.processResponse(
          response: pollResponse,
          ohttpCtx: pollReqCtx.ohttpCtx,
        );
        final outcome = pollTransition.save(persister: persister);
        printV('[pjSender] poll outcome=${outcome.runtimeType}');

        if (outcome is pj.ProgressPollingForProposalTransitionOutcome) {
          printV('[pjSender] Progress; psbtLen=${outcome.psbtBase64.length}');
          return outcome.psbtBase64;
        }
        polling = (outcome as pj.StasisPollingForProposalTransitionOutcome).inner;
        printV('[pjSender] Stasis; will retry');
      } catch (e, s) {
        if (e is pj.ResponseException) {
          printV('Payjoin poll recoverable error: $e');
        } else {
          printV('[pjSender] poll FATAL: $e\n$s');
          rethrow;
        }
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<Uint8List> _httpPost(pj.Request request) async {
    final httpResponse = await client.post(
      Uri.parse(request.url),
      headers: {'Content-Type': request.contentType},
      body: request.body,
    );
    return httpResponse.bodyBytes;
  }
}

class PayjoinSenderCancelledException implements Exception {
  @override
  String toString() => 'PayjoinSenderCancelledException';
}

class _InMemorySenderPersister extends pj.JsonSenderSessionPersister {
  final List<String> _events = [];

  @override
  void save(String event) => _events.add(event);

  @override
  List<String> load() => List.from(_events);

  @override
  void close() => _events.clear();
}
