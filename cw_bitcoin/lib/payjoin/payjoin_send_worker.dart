import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:cw_bitcoin/payjoin/mailroom_manager.dart";
import "package:cw_bitcoin/payjoin/payjoin_session_errors.dart";
import "package:cw_bitcoin/payjoin/relay_response.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:http/http.dart" as very_insecure_http_do_not_use;
import "package:payjoin/payjoin.dart" as pj;

/// Maximum wall-clock duration a sender worker will keep polling for a
/// proposal before giving up. Mirrors the v2 protocol's typical session
/// expiry window; the FFI also surfaces explicit terminal states which we
/// handle separately.
const _maxSenderSessionDuration = Duration(hours: 24);
const _initialBackoff = Duration(seconds: 2);
const _maxBackoff = Duration(seconds: 30);

/// Per-request cap so a relay that accepts the connection but never
/// responds (common over Tor) can't stall the retry loop forever — the
/// timeout surfaces as a SocketException and the next relay is tried.
const _relayRequestTimeout = Duration(seconds: 10);

/// Drives the v2 Payjoin sender state machine.
///
/// Mirrors `payjoin-cli`'s `process_sender_session` driver:
///   WithReplyKey -> PollingForProposal -> Closed(Success)
///
/// A session is created up-front by [createSession]; the worker then drives
/// it from its persisted event log via [resume] (`replaySenderEventLog`,
/// matching [PayjoinReceiverWorker]'s replay path), both for a new send and
/// after a wallet switch / app restart.
class PayjoinSenderWorker {
  PayjoinSenderWorker({
    required MailroomManager mailroomManager,
    required pj.JsonSenderSessionPersister persister,
    this.directory,
  })  : _mailroomManager = mailroomManager,
        _persister = persister;

  // The receiver's payjoin directory (the `pj=` endpoint). Relays on the
  // same host are never used: one operator holding both OHTTP roles could
  // link this client's IP to the payjoin payload.
  final String? directory;

  final client = ProxyWrapper().getHttpIOClient();
  final MailroomManager _mailroomManager;
  final pj.JsonSenderSessionPersister _persister;
  bool _cancelled = false;
  bool _disposed = false;

  /// Signals the polling loops to stop at the next iteration. Does not release
  /// resources — call [dispose] for that.
  void cancel() => _cancelled = true;

  /// Releases the underlying HTTP client (sockets, TLS state). Idempotent.
  /// Safe to call from any terminal path; the polling loops will throw on the
  /// next iteration if [cancel] has also been called.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    client.close();
  }

  /// Builds a new sender session for [psbtBase64] and persists its first
  /// state into [persister], without any network I/O. Throws when the
  /// session can't be built (e.g. the payee output doesn't match the
  /// request's `amount=`), before anything reaches the receiver.
  ///
  /// Refuses a persister that already holds events: those belong to an
  /// earlier send to the same endpoint, and continuing them would sign that
  /// send's original instead of [psbtBase64].
  static void createSession({
    required String psbtBase64,
    required String pjUriString,
    required int minFeeRateSatPerKwu,
    required pj.JsonSenderSessionPersister persister,
  }) {
    if (persister.load().isNotEmpty) {
      throw const PayjoinEndpointAlreadyUsedError();
    }
    final pjUri = pj.Uri.parse(uri: pjUriString).checkPjSupported();
    pj.SenderBuilder(psbt: psbtBase64, uri: pjUri)
        .buildRecommended(minFeeRateSatPerKwu: minFeeRateSatPerKwu)
        .save(persister: persister);
  }

  DateTime _sessionDeadline() => DateTime.now().add(_maxSenderSessionDuration);

  /// Drives the session from its persisted event log: a session just made
  /// by [createSession], or one re-spawned after a wallet switch / app
  /// restart (the replayed FFI state contains everything needed to
  /// continue).
  Future<String> resume() {
    if (_cancelled) {
      throw const PayjoinSenderCancelledException();
    }
    final persister = _persister;
    final events = persister.load();
    if (events.isEmpty) {
      throw StateError("Cannot resume sender: event log is empty");
    }
    printV("[pjSender] resuming from ${events.length} event(s)");
    return _runFromReplay(persister, _sessionDeadline());
  }

  Future<String> _runFromReplay(
    pj.JsonSenderSessionPersister persister,
    DateTime deadline,
  ) async {
    final replayResult = pj.replaySenderEventLog(persister: persister);
    final state = replayResult.state();
    replayResult.dispose();

    if (state is pj.WithReplyKeySendSession) {
      printV("[pjSender] replay -> WithReplyKey; posting original proposal");
      final polling = await _postOriginalProposal(state.inner, persister, deadline);
      return _pollForProposal(polling, persister, deadline);
    }
    if (state is pj.PollingForProposalSendSession) {
      printV("[pjSender] replay -> PollingForProposal; continuing");
      return _pollForProposal(state.inner, persister, deadline);
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
        if (psbt != null) {
          return psbt;
        }
      }
      throw Exception("Sender session already closed without a proposal");
    }
    throw Exception("Sender session not resumable: ${state.runtimeType}");
  }

  Future<pj.PollingForProposal> _postOriginalProposal(
    pj.WithReplyKey withReplyKey,
    pj.JsonSenderSessionPersister persister,
    DateTime deadline,
  ) async {
    var consecutiveFailures = 0;
    while (true) {
      try {
        final relayResponse = await _postViaRelay(
          (relay) => withReplyKey.createV2PostRequest(ohttpRelay: relay),
          deadline: deadline,
        );
        printV("[pjSender] POST subscribe -> ${relayResponse.requestUrl}");
        final transition = withReplyKey.processResponse(
          response: relayResponse.bodyBytes,
          postCtx: relayResponse.ohttpCtx,
        );
        return transition.save(persister: persister);
      } on pj.TransientSenderPersistedException catch (e) {
        printV("[pjSender] post retry: $e");
      } catch (e) {
        throw _classify(e);
      }
      if (_cancelled) {
        throw const PayjoinSenderCancelledException();
      }
      await Future.delayed(_nextBackoff(consecutiveFailures++));
    }
  }

  /// Transient errors persisted nothing and are retried by the callers;
  /// everything else ends the session (fatal errors already closed it in the
  /// event log, and an expired session can never send another request).
  Object _classify(Object e) {
    if (e is pj.CreateRequestException) {
      return UnrecoverableError(e.isExpired() ? "Session expired" : "Cannot create request: $e");
    }
    return e;
  }

  Future<String> _pollForProposal(
    pj.PollingForProposal polling,
    pj.JsonSenderSessionPersister persister,
    DateTime deadline,
  ) async {
    var consecutiveFailures = 0;
    while (true) {
      if (_cancelled) {
        throw const PayjoinSenderCancelledException();
      }
      if (DateTime.now().isAfter(deadline)) {
        throw Exception("Payjoin sender session expired before a proposal arrived");
      }
      printV("Polling Payjoin Sender Proposal");
      try {
        final relayResponse = await _postViaRelay(
          (relay) => polling.createPollRequest(ohttpRelay: relay),
          deadline: deadline,
        );
        final pollTransition = polling.processResponse(
          response: relayResponse.bodyBytes,
          ohttpCtx: relayResponse.ohttpCtx,
        );
        final outcome = pollTransition.save(persister: persister);
        consecutiveFailures = 0;
        printV("[pjSender] poll outcome=${outcome.runtimeType}");

        if (outcome is pj.ProgressPollingForProposalTransitionOutcome) {
          printV("[pjSender] Progress; psbtLen=${outcome.psbtBase64.length}");
          return outcome.psbtBase64;
        }
        polling = (outcome as pj.StasisPollingForProposalTransitionOutcome).inner;
        printV("[pjSender] Stasis; will retry");
      } on PayjoinSenderCancelledException {
        rethrow;
      } on PayjoinSenderFallbackAvailableException {
        rethrow;
      } on pj.TransientSenderPersistedException catch (e) {
        printV("[pjSender] poll retry: $e");
      } catch (e, s) {
        printV("[pjSender] poll FATAL: $e\n$s");
        throw _classify(e);
      }
      await Future.delayed(_nextBackoff(consecutiveFailures++));
    }
  }

  Future<PayjoinRelayResponse> _postViaRelay(
    pj.RequestOhttpContext Function(String relay) buildRequest, {
    required DateTime deadline,
  }) async {
    var consecutiveFailures = 0;
    while (true) {
      if (_cancelled) {
        throw const PayjoinSenderCancelledException();
      }
      if (DateTime.now().isAfter(deadline)) {
        throw Exception("Payjoin sender session expired before relay connectivity returned");
      }
      // Stateless relay choice: every pick is random over the full
      // configured pool. A broken relay costs one wasted request per
      // round; the next pick naturally spreads load across the pool.
      // Retries are bounded by [deadline], not by failure marks.
      final String relay;
      try {
        relay = _mailroomManager.chooseRelay(
          excludeHost: directory == null ? null : Uri.tryParse(directory!)?.host,
        );
      } on StateError {
        throw const UnrecoverableError("No payjoin relay configured apart from the directory host");
      }
      // FFI/protocol errors raised while building the request are NOT relay
      // problems — propagate them so the caller sees the real cause.
      final reqCtx = buildRequest(relay);
      try {
        final response = await client
            .post(
              Uri.parse(reqCtx.request.url),
              headers: {"Content-Type": reqCtx.request.contentType},
              body: reqCtx.request.body,
            )
            .timeout(
              _relayRequestTimeout,
              onTimeout: () => throw SocketException("relay $relay request timed out"),
            );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return PayjoinRelayResponse(
            bodyBytes: response.bodyBytes,
            ohttpCtx: reqCtx.ohttpCtx,
            requestUrl: reqCtx.request.url,
          );
        }
        // Non-2xx from the relay itself (OHTTP wraps the directory response,
        // so the relay's status is its own) — try again.
        printV("[pjSender] relay $relay returned HTTP ${response.statusCode}");
      } on IOException catch (e) {
        // Transport failure of any kind — socket, TLS handshake, HTTP
        // protocol, request timeout. Try the next pick. A cancel disposes
        // the HTTP client mid-request, surfacing as one of these — exit
        // as a cancellation instead.
        if (_cancelled) {
          throw const PayjoinSenderCancelledException();
        }
        printV("[pjSender] relay $relay transport error: $e");
      } on very_insecure_http_do_not_use.ClientException catch (e) {
        if (_cancelled) {
          throw const PayjoinSenderCancelledException();
        }
        printV("[pjSender] relay $relay transport error: $e");
      }
      await Future.delayed(_nextBackoff(consecutiveFailures++));
    }
  }
}

Duration _nextBackoff(int consecutiveFailures) {
  if (consecutiveFailures == 0) {
    return _initialBackoff;
  }
  final seconds = (_initialBackoff.inSeconds * (1 << consecutiveFailures))
      .clamp(_initialBackoff.inSeconds, _maxBackoff.inSeconds);
  return Duration(seconds: seconds);
}

class PayjoinSenderCancelledException extends PayjoinSessionError {
  const PayjoinSenderCancelledException() : super("Payjoin sender session cancelled");
}

/// Thrown when a replayed sender session is already in the
/// `SenderPendingFallback` state, meaning the user must broadcast the
/// enclosed fallback transaction to settle the original payment.
class PayjoinSenderFallbackAvailableException extends PayjoinSessionError {
  PayjoinSenderFallbackAvailableException(this.fallbackTx)
      : super("Fallback transaction ready to broadcast");
  final Uint8List fallbackTx;
}
