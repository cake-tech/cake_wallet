import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_bitcoin/payjoin/mailroom_manager.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:payjoin/payjoin.dart' as pj;

/// Drives the v2 Payjoin sender state machine.
///
/// Mirrors `payjoin-cli`'s `process_sender_session` driver:
///   WithReplyKey -> PollingForProposal -> Closed(Success)
///
/// On [run], if [persister] already holds events the worker resumes via
/// `replaySenderEventLog` (matching [PayjoinReceiverWorker]'s replay path).
/// Otherwise it builds a fresh [pj.SenderBuilder] from the original PSBT and
/// uri, then proceeds through the state machine.
class PayjoinSenderWorker {
  PayjoinSenderWorker({
    required MailroomManager mailroomManager,
    pj.JsonSenderSessionPersister? persister,
  })  : _mailroomManager = mailroomManager,
        _persister = persister;

  final MailroomManager _mailroomManager;
  final http.Client client = ProxyWrapper().getHttpIOClient();
  final pj.JsonSenderSessionPersister? _persister;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<String> run(
    String psbtBase64,
    String pjUriString,
    int minFeeRateSatPerKwu,
  ) async {
    if (_cancelled) throw PayjoinSenderCancelledException();
    final persister = _persister ?? _InMemorySenderPersister();
    final events = persister.load();

    if (events.isNotEmpty) {
      printV('[pjSender] resuming from ${events.length} event(s)');
      return _runFromReplay(persister);
    }

    return _runFresh(psbtBase64, pjUriString, minFeeRateSatPerKwu, persister);
  }

  Future<String> _runFromReplay(
    pj.JsonSenderSessionPersister persister,
  ) async {
    final replayResult = pj.replaySenderEventLog(persister: persister);
    final state = replayResult.state();
    replayResult.dispose();

    if (state is pj.WithReplyKeySendSession) {
      printV('[pjSender] replay -> WithReplyKey; posting original proposal');
      final polling = await _postOriginalProposal(state.inner, persister);
      return _pollForProposal(polling, persister);
    }
    if (state is pj.PollingForProposalSendSession) {
      printV('[pjSender] replay -> PollingForProposal; continuing');
      return _pollForProposal(state.inner, persister);
    }
    if (state is pj.SenderPendingFallbackSendSession) {
      throw PayjoinSenderFallbackAvailableException(
        state.inner.fallbackTx(),
      );
    }
    if (state is pj.ClosedSendSession) {
      final outcome = state.inner;
      if (outcome.isSuccess()) {
        final psbt = outcome.successPsbtBase64();
        if (psbt != null) return psbt;
      }
      throw Exception('Sender session already closed without a proposal');
    }
    throw Exception('Sender session not resumable: ${state.runtimeType}');
  }

  Future<String> _runFresh(
    String psbtBase64,
    String pjUriString,
    int minFeeRateSatPerKwu,
    pj.JsonSenderSessionPersister persister,
  ) async {
    final pjUri = pj.Uri.parse(uri: pjUriString).checkPjSupported();
    final builder = pj.SenderBuilder(psbt: psbtBase64, uri: pjUri);
    final initialTransition = builder.buildRecommended(
      minFeeRateSatPerKwu: minFeeRateSatPerKwu,
    );
    final withReplyKey = initialTransition.save(persister: persister);

    final polling = await _postOriginalProposal(withReplyKey, persister);
    return _pollForProposal(polling, persister);
  }

  Future<pj.PollingForProposal> _postOriginalProposal(
    pj.WithReplyKey withReplyKey,
    pj.JsonSenderSessionPersister persister,
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

  Future<String> _pollForProposal(
    pj.PollingForProposal polling,
    pj.JsonSenderSessionPersister persister,
  ) async {
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
      } on PayjoinSenderFallbackAvailableException {
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

/// Thrown when a replayed sender session is already in the
/// `SenderPendingFallback` state, meaning the user must broadcast the
/// enclosed fallback transaction to settle the original payment.
class PayjoinSenderFallbackAvailableException implements Exception {
  PayjoinSenderFallbackAvailableException(this.fallbackTx);
  final Uint8List fallbackTx;

  @override
  String toString() =>
      'PayjoinSenderFallbackAvailableException(fallbackTxLen=${fallbackTx.length})';
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
