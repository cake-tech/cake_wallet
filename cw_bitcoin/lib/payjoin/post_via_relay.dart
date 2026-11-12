import "dart:io";
import "dart:math";

import "package:cw_bitcoin/payjoin/mailroom_manager.dart";
import "package:cw_bitcoin/payjoin/payjoin_session_errors.dart";
import "package:cw_bitcoin/payjoin/relay_response.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:http/http.dart" as very_insecure_http_do_not_use;
import "package:payjoin/payjoin.dart" as pj;

const _initialBackoff = Duration(seconds: 2);
const _maxBackoff = Duration(seconds: 30);

/// Per-request cap so a relay that accepts the connection but never
/// responds (common over Tor) can't stall the retry loop forever — the
/// timeout surfaces as a SocketException and the next relay is tried.
const _relayRequestTimeout = Duration(seconds: 10);

/// An OHTTP-encapsulated request plus the context needed to decrypt its
/// response. Normalizes the FFI's sender (`RequestOhttpContext`) and
/// receiver (`RequestResponse`) request types.
typedef RelayRequest = ({pj.Request request, pj.ClientResponse ohttpCtx});

/// POSTs the request built by [buildRequest] through a relay, retrying with
/// backoff on relay/transport failures until [deadline].
///
/// Relays hosted on the [directory]'s host are never used: one operator
/// holding both OHTTP roles could link this client's IP to the payjoin
/// payload. Throws [cancelledError] once [isCancelled] reports true and
/// [expiredError] once [deadline] passes.
Future<PayjoinRelayResponse> postViaRelay({
  required very_insecure_http_do_not_use.Client client,
  required MailroomManager mailroomManager,
  required String? directory,
  required RelayRequest Function(String relay) buildRequest,
  required DateTime deadline,
  required bool Function() isCancelled,
  required PayjoinSessionError cancelledError,
  required PayjoinSessionError expiredError,
  required String logTag,
}) async {
  final directoryHost = directory == null ? null : Uri.tryParse(directory)?.host;
  var consecutiveFailures = 0;
  while (true) {
    if (isCancelled()) {
      throw cancelledError;
    }
    if (DateTime.now().isAfter(deadline)) {
      throw expiredError;
    }
    // Stateless relay choice: every pick is random over the full
    // configured pool. A broken relay costs one wasted request per
    // round; the next pick naturally spreads load across the pool.
    // Retries are bounded by [deadline], not by failure marks.
    final String relay;
    try {
      relay = mailroomManager.chooseRelay(excludeHost: directoryHost);
    } on StateError {
      throw const UnrecoverableError("No payjoin relay configured apart from the directory host");
    }
    // FFI/protocol errors raised while building the request are NOT relay
    // problems — propagate them so the caller sees the real cause.
    final relayRequest = buildRequest(relay);
    try {
      final response = await client
          .post(
            Uri.parse(relayRequest.request.url),
            headers: {"Content-Type": relayRequest.request.contentType},
            body: relayRequest.request.body,
          )
          .timeout(
            _relayRequestTimeout,
            onTimeout: () => throw SocketException("relay $relay request timed out"),
          );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PayjoinRelayResponse(
          bodyBytes: response.bodyBytes,
          ohttpCtx: relayRequest.ohttpCtx,
          requestUrl: relayRequest.request.url,
        );
      }
      // Non-2xx from the relay itself (OHTTP wraps the directory response,
      // so the relay's status is its own) — try again.
      printV("[$logTag] relay $relay returned HTTP ${response.statusCode}");
    } on IOException catch (e) {
      // Transport failure of any kind — socket, TLS handshake, HTTP
      // protocol, request timeout. Try the next pick. A cancel disposes
      // the HTTP client mid-request, surfacing as one of these — exit
      // as a cancellation instead.
      if (isCancelled()) {
        throw cancelledError;
      }
      printV("[$logTag] relay $relay transport error: $e");
    } on very_insecure_http_do_not_use.ClientException catch (e) {
      if (isCancelled()) {
        throw cancelledError;
      }
      printV("[$logTag] relay $relay transport error: $e");
    }
    await Future.delayed(nextRelayBackoff(consecutiveFailures++));
  }
}

/// Exponential backoff from 2s, capped at 30s.
Duration nextRelayBackoff(int consecutiveFailures) {
  if (consecutiveFailures == 0) {
    return _initialBackoff;
  }
  final seconds = (_initialBackoff.inSeconds * (1 << min(consecutiveFailures, 4)))
      .clamp(_initialBackoff.inSeconds, _maxBackoff.inSeconds);
  return Duration(seconds: seconds);
}
