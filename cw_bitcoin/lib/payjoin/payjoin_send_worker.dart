import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_bitcoin/payjoin/mailroom_manager.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:payjoin/payjoin.dart' as pj;

class PayjoinSenderWorker {
  PayjoinSenderWorker({
    required MailroomManager mailroomManager,
  }) : _mailroomManager = mailroomManager;

  final MailroomManager _mailroomManager;
  final http.Client client = ProxyWrapper().getHttpIOClient();
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<String> run(
    String psbtBase64,
    String pjUriString,
    int minFeeRateSatPerKwu,
  ) async {
    final pjUri = pj.Uri.parse(uri: pjUriString).checkPjSupported();
    final builder = pj.SenderBuilder(psbt: psbtBase64, uri: pjUri);
    final initialTransition = builder.buildRecommended(
      minFeeRateSatPerKwu: minFeeRateSatPerKwu,
    );
    final persister = _InMemorySenderPersister();
    final withReplyKey = initialTransition.save(persister: persister);

    var polling = await _postOriginalProposal(withReplyKey, persister);

    while (true) {
      if (_cancelled) throw PayjoinSenderCancelledException();
      printV('Polling Payjoin Sender Proposal');
      try {
        final relayResponse = await _postViaRelay(
          (relay) => polling.createPollRequest(ohttpRelay: relay),
        );
        final pollTransition = polling.processResponse(
          response: relayResponse.bodyBytes,
          ohttpCtx: relayResponse.ohttpCtx,
        );
        final outcome = pollTransition.save(persister: persister);
        printV('[pjSender] poll outcome=${outcome.runtimeType}');

        if (outcome is pj.ProgressPollingForProposalTransitionOutcome) {
          printV('[pjSender] Progress; psbtLen=${outcome.psbtBase64.length}');
          return outcome.psbtBase64;
        }
        polling = (outcome as pj.StasisPollingForProposalTransitionOutcome).inner;
        printV('[pjSender] Stasis; will retry');
      } on PayjoinSenderCancelledException {
        rethrow;
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

  Future<pj.PollingForProposal> _postOriginalProposal(
    pj.WithReplyKey withReplyKey,
    _InMemorySenderPersister persister,
  ) async {
    final relayResponse = await _postViaRelay(
      (relay) => withReplyKey.createV2PostRequest(ohttpRelay: relay),
    );
    printV('[pjSender] POST subscribe -> ${relayResponse.requestUrl}');
    final transition = withReplyKey.processResponse(
      response: relayResponse.bodyBytes,
      postCtx: relayResponse.ohttpCtx,
    );
    return transition.save(persister: persister);
  }

  Future<_RelayResponse> _postViaRelay(
    pj.RequestOhttpContext Function(String relay) buildRequest,
  ) async {
    while (true) {
      final relay = _mailroomManager.chooseRelay();
      final reqCtx = buildRequest(relay);
      try {
        final response = await client.post(
          Uri.parse(reqCtx.request.url),
          headers: {'Content-Type': reqCtx.request.contentType},
          body: reqCtx.request.body,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _RelayResponse(
            bodyBytes: response.bodyBytes,
            ohttpCtx: reqCtx.ohttpCtx,
            requestUrl: reqCtx.request.url,
          );
        }
        throw HttpException('HTTP ${response.statusCode}');
      } catch (e) {
        printV('[pjSender] relay $relay failed: $e');
        _mailroomManager.addFailedRelay(relay);
      }
    }
  }
}

class _RelayResponse {
  final Uint8List bodyBytes;
  final pj.ClientResponse ohttpCtx;
  final String requestUrl;

  _RelayResponse({
    required this.bodyBytes,
    required this.ohttpCtx,
    required this.requestUrl,
  });
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
