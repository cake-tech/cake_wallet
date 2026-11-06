import 'dart:io';
import 'dart:typed_data';

import 'package:cw_bitcoin/payjoin/mailroom_manager.dart';
import 'package:cw_bitcoin/payjoin/payjoin_session_errors.dart';
import 'package:cw_bitcoin/payjoin/payjoin_signer.dart';
import 'package:cw_bitcoin/payjoin/relay_response.dart';
import 'package:cw_bitcoin/psbt/signer.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:payjoin/payjoin.dart' as pj;

/// Maximum wall-clock duration a receiver worker will keep polling for an
/// original payload before giving up. Matches the v2 protocol's typical
/// receiver session lifetime; longer-running sessions should be restarted by
/// the user with a fresh endpoint.
const _maxReceiverSessionDuration = Duration(hours: 24);
const _initialBackoff = Duration(seconds: 2);
const _maxBackoff = Duration(seconds: 30);
/// Per-request cap so a relay that accepts the connection but never
/// responds (common over Tor) can't stall the retry loop forever — the
/// timeout surfaces as a SocketException and the next relay is tried.
const _relayRequestTimeout = Duration(seconds: 10);

class _IsScriptOwned extends pj.IsScriptOwned {
  final bool Function(Uint8List) fn;
  _IsScriptOwned(this.fn);
  @override
  bool callback(Uint8List script) => fn(script);
}

class _IsOutputKnown extends pj.IsOutputKnown {
  final bool Function(pj.OutPoint) fn;
  _IsOutputKnown(this.fn);
  @override
  bool callback(pj.OutPoint outpoint) => fn(outpoint);
}

class _IsInputOwned extends pj.IsInputOwned {
  final bool Function(pj.OutPoint) fn;
  _IsInputOwned(this.fn);
  @override
  bool callback(pj.OutPoint outpoint) => fn(outpoint);
}

class _ProcessPsbt extends pj.ProcessPsbt {
  final String Function(String) fn;
  _ProcessPsbt(this.fn);
  @override
  String callback(String psbt) => fn(psbt);
}

class PayjoinReceiverWorker {
  PayjoinReceiverWorker({
    required MailroomManager mailroomManager,
    required this.utxos,
    required this.isMineChecker,
    required this.isOutpointOwned,
    this.getCurrentHeight,
    pj.JsonReceiverSessionPersister? persister,
    void Function()? onProposalReceived,
  })  : _mailroomManager = mailroomManager,
        _persister = persister,
        _onProposalReceived = onProposalReceived;

  final MailroomManager _mailroomManager;
  final http.Client client = ProxyWrapper().getHttpIOClient();
  final List<UtxoWithPrivateKey> utxos;
  final bool Function(Uint8List) isMineChecker;
  // Consults the wallet's full tracked UTXO set (frozen, unconfirmed,
  // marked-sending included) at check time — NOT the spendable snapshot in
  // [utxos] — so checkInputsNotOwned can't be bypassed by referencing a
  // wallet-owned outpoint that falls outside that snapshot.
  final bool Function(String txid, int vout) isOutpointOwned;
  final int Function()? getCurrentHeight;
  final pj.JsonReceiverSessionPersister? _persister;
  final void Function()? _onProposalReceived;
  bool _cancelled = false;
  bool _disposed = false;

  /// Wall-clock deadline shared by every relay round-trip of one session
  /// (polling and the final proposal post), so relay retry loops inside
  /// [_postViaRelay] can't spin past the receiver session lifetime.
  DateTime _sessionDeadline =
      DateTime.now().add(_maxReceiverSessionDuration);

  /// Signals the polling loops to stop at the next iteration. Does not release
  /// resources — call [dispose] for that.
  void cancel() => _cancelled = true;

  /// Releases the underlying HTTP client (sockets, TLS state). Idempotent.
  /// Safe to call from any terminal path; the polling loops will throw on the
  /// next iteration if [cancel] has also been called.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    client.close();
  }

  Future<String> run(String address, String directory, pj.OhttpKeys ohttpKeys) async {
    try {
      if (_cancelled) throw CancelException();
      _sessionDeadline = DateTime.now().add(_maxReceiverSessionDuration);
      final persister = _persister ?? _InMemoryReceiverPersister();
      final events = persister.load();

      if (events.isNotEmpty) {
        return _runFromReplay(persister);
      }

      return _runFresh(address, directory, ohttpKeys, persister);
    } catch (e) {
      printV('PayjoinReceiverWorker error: $e');
      rethrow;
    }
  }

  /// Resumes a receiver session from its persisted event log. Used when the
  /// worker is re-spawned after a wallet switch / app restart and the
  /// directory + ohttpKeys are no longer at hand (they live inside the
  /// replayed FFI state). Requires a persister to have been supplied at
  /// construction time.
  Future<String> resume() async {
    try {
      if (_cancelled) throw CancelException();
      _sessionDeadline = DateTime.now().add(_maxReceiverSessionDuration);
      final persister = _persister;
      if (persister == null) {
        throw StateError('Cannot resume receiver without a persister');
      }
      if (persister.load().isEmpty) {
        throw StateError('Cannot resume receiver: event log is empty');
      }
      return _runFromReplay(persister);
    } catch (e) {
      printV('PayjoinReceiverWorker resume error: $e');
      rethrow;
    }
  }

  Future<String> _runFromReplay(
    pj.JsonReceiverSessionPersister persister,
  ) async {
    final replayResult = pj.replayReceiverEventLog(persister: persister);
    final state = replayResult.state();
    replayResult.dispose();

    if (state is pj.InitializedReceiveSession) {
      return _processFromInitialized(state.inner, persister);
    }
    if (state is pj.UncheckedOriginalPayloadReceiveSession) {
      _onProposalReceived?.call();
      final maybeInputsOwned = state.inner.assumeInteractiveReceiver().save(persister: persister);
      return _processFromMaybeInputsOwned(maybeInputsOwned, persister);
    }
    if (state is pj.MaybeInputsOwnedReceiveSession) {
      _onProposalReceived?.call();
      return _processFromMaybeInputsOwned(state.inner, persister);
    }
    if (state is pj.ClosedReceiveSession) {
      throw Exception('Session already completed');
    }
    // Resume from any deeper intermediate state by extracting the inner
    // type and walking the processing chain forward.
    final proposal = await _resumeFromState(state, persister);
    return _sendFinalProposal(proposal, persister);
  }

  /// Dispatches on every concrete [ReceiveSession] variant, extracts the
  /// inner state object, and feeds it into the processing chain.  Each step
  /// that has already been completed (because the event log is past it) is
  /// skipped; the first unprocessed step picks up from there.
  Future<pj.PayjoinProposal> _resumeFromState(
    pj.ReceiveSession state,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    if (state is pj.MaybeInputsSeenReceiveSession) {
      return _runProcessingChain(state.inner, persister);
    }
    if (state is pj.OutputsUnknownReceiveSession) {
      return _runProcessingChain(state.inner, persister);
    }
    if (state is pj.WantsOutputsReceiveSession) {
      return _runProcessingChain(state.inner, persister);
    }
    if (state is pj.WantsInputsReceiveSession) {
      return _runProcessingChain(state.inner, persister);
    }
    if (state is pj.WantsFeeRangeReceiveSession) {
      return _runProcessingChain(state.inner, persister);
    }
    if (state is pj.ProvisionalProposalReceiveSession) {
      return _runProcessingChain(state.inner, persister);
    }
    if (state is pj.PayjoinProposalReceiveSession) {
      return state.inner;
    }
    // Terminal / non-resumable states
    if (state is pj.HasReplyableExceptionReceiveSession) {
      throw RecoverableError('session in HasReplyableException state');
    }
    if (state is pj.MonitorReceiveSession) {
      throw RecoverableError('session in Monitor state');
    }
    if (state is pj.ReceiverPendingFallbackReceiveSession) {
      throw RecoverableError('session in PendingFallback state');
    }
    throw RecoverableError(
      'Cannot continue from unexpected session state: ${state.runtimeType}',
    );
  }

  Future<String> _runFresh(String address, String directory, pj.OhttpKeys ohttpKeys,
      pj.JsonReceiverSessionPersister persister) async {
    final builder = pj.ReceiverBuilder(
      address: address,
      directory: directory,
      ohttpKeys: ohttpKeys,
    );
    final initialTransition = builder.build();
    final initialized = initialTransition.save(persister: persister);

    return _processFromInitialized(initialized, persister);
  }

  Future<String> _processFromInitialized(
    pj.Initialized initialized,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    final uncheckedProposal = await _pollForProposal(initialized, persister);
    _onProposalReceived?.call();
    final maybeInputsOwned =
        uncheckedProposal.assumeInteractiveReceiver().save(persister: persister);

    return _processFromMaybeInputsOwned(maybeInputsOwned, persister);
  }

  Future<String> _processFromMaybeInputsOwned(
    pj.MaybeInputsOwned maybeInputsOwned,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    final payjoinProposal = await _processPayjoinProposal(maybeInputsOwned, persister);
    return _sendFinalProposal(payjoinProposal, persister);
  }

  Future<pj.UncheckedOriginalPayload> _pollForProposal(
    pj.Initialized initialized,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    var consecutiveFailures = 0;
    while (true) {
      if (_cancelled) throw CancelException();
      if (DateTime.now().isAfter(_sessionDeadline)) {
        throw RecoverableError('Payjoin receiver session expired before a proposal arrived');
      }
      printV('Polling for Proposal');
      try {
        final relayResponse = await _postViaRelay(
          (relay) => initialized.createPollRequest(ohttpRelay: relay),
          deadline: _sessionDeadline,
        );
        final transition = initialized.processResponse(
          body: relayResponse.bodyBytes,
          ctx: relayResponse.ohttpCtx,
        );
        final outcome = transition.save(persister: persister);
        consecutiveFailures = 0;

        if (outcome is pj.ProgressInitializedTransitionOutcome) {
          return outcome.inner;
        }
        initialized = (outcome as pj.StasisInitializedTransitionOutcome).inner;
      } catch (e) {
        if (e is pj.ResponseException || e is pj.ProtocolException) {
          printV('Poll failed: $e');
          rethrow;
        }
        printV('Poll retry: $e');
      }
      await Future.delayed(_nextBackoff(consecutiveFailures++));
    }
  }

  Future<pj.PayjoinProposal> _processPayjoinProposal(
    pj.MaybeInputsOwned maybeInputsOwned,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    try {
      final checkOwned = _wrapSync(
        () => maybeInputsOwned.checkInputsNotOwned(
          isOwned: _IsInputOwned(
            (outpoint) =>
                isOutpointOwned(outpoint.txid, outpoint.vout),
          ),
        ),
        'checkInputsNotOwned',
      );
      final maybeInputsSeen = checkOwned.save(persister: persister);
      return _runProcessingChain(maybeInputsSeen, persister);
    } catch (e) {
      if (e is RecoverableError) rethrow;
      throw RecoverableError('_processPayjoinProposal failed at step: $e');
    }
  }

  /// Walks the receive processing chain from whatever state [current] is at,
  /// advancing through every subsequent step until a [PayjoinProposal] is
  /// produced.  Each type-check block is skipped when the state has already
  /// progressed past that point (the chain is safe to call from any entry).
  Future<pj.PayjoinProposal> _runProcessingChain(
    dynamic current,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    try {
      // MaybeInputsSeen → OutputsUnknown
      if (current is pj.MaybeInputsSeen) {
        final checkSeen = _wrapSync(
          () => current.checkNoInputsSeenBefore(
            isKnown: _IsOutputKnown((_) => false),
          ),
          'checkNoInputsSeenBefore',
        );
        current = checkSeen.save(persister: persister);
      }

      // OutputsUnknown → WantsOutputs
      if (current is pj.OutputsUnknown) {
        final identifyOutputs = _wrapSync(
          () => current.identifyReceiverOutputs(
            isReceiverOutput: _IsScriptOwned(isMineChecker),
          ),
          'identifyReceiverOutputs',
        );
        current = identifyOutputs.save(persister: persister);
      }

      // WantsOutputs → WantsInputs
      if (current is pj.WantsOutputs) {
        final transition = current.commitOutputs();
        current = transition.save(persister: persister);
      }

      // WantsInputs → WantsFeeRange
      if (current is pj.WantsInputs) {
        final candidateInputs = _buildInputPairs();
        if (candidateInputs.isEmpty) {
          throw RecoverableError('No unspent outputs available');
        }
        pj.InputPair selectedUtxo = candidateInputs.first;
        try {
          selectedUtxo = current.tryPreservingPrivacy(
            candidateInputs: candidateInputs,
          );
        } catch (_) {}
        current = current.contributeInputs(
          replacementInputs: [selectedUtxo],
        );
        final commitTransition = current.commitInputs();
        current = commitTransition.save(persister: persister);
      }

      // WantsFeeRange → ProvisionalProposal
      if (current is pj.WantsFeeRange) {
        final applyFeeRangeTransition = _wrapSync(
          () => current.applyFeeRange(
            minFeeRateSatPerVb: null,
            maxEffectiveFeeRateSatPerVb: 10000,
          ),
          'applyFeeRange',
        );
        current = applyFeeRangeTransition.save(persister: persister);
      }

      // ProvisionalProposal → PayjoinProposal
      if (current is pj.ProvisionalProposal) {
        printV('PSBT to sign received (len=${current.psbtToSign().length})');
        final finalizeTransition = _wrapSync(
          () => current.finalizeProposal(
            processPsbt: _ProcessPsbt(
              (psbt) => signPsbtSync(psbt, utxos),
            ),
          ),
          'finalizeProposal',
        );
        current = finalizeTransition.save(persister: persister);
      }

      if (current is pj.PayjoinProposal) {
        return current;
      }

      throw RecoverableError('Unexpected state in chain: ${current.runtimeType}');
    } catch (e) {
      if (e is RecoverableError) rethrow;
      throw RecoverableError('_processPayjoinProposal failed at step: $e');
    }
  }

  List<pj.InputPair> _buildInputPairs() {
    printV('PayjoinReceiverWorker: building input pairs from ${utxos.length} utxos');
    return utxos.map((utxo) {
      final btcUtxo = utxo.utxo;
      final scriptPubkey = Uint8List.fromList(utxo.ownerDetails.address.toScriptPubKey().toBytes());
      return pj.InputPair(
        txin: pj.TxIn(
          previousOutput: pj.OutPoint(
            txid: btcUtxo.txHash,
            vout: btcUtxo.vout,
          ),
          scriptSig: Uint8List(0),
          sequence: 0,
          witness: [],
        ),
        psbtin: pj.PsbtInput(
          witnessUtxo: pj.TxOut(
            valueSat: btcUtxo.value.toInt(),
            scriptPubkey: scriptPubkey,
          ),
          redeemScript: null,
          witnessScript: null,
        ),
        expectedWeight: null,
      );
    }).toList();
  }

  Future<String> _sendFinalProposal(
    pj.PayjoinProposal proposal,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    final relayResponse = await _postViaRelay(
      (relay) => proposal.createPostRequest(ohttpRelay: relay),
      deadline: _sessionDeadline,
    );
    final transition = proposal.processResponse(
      body: relayResponse.bodyBytes,
      ohttpContext: relayResponse.ohttpCtx,
    );
    transition.save(persister: persister);
    return proposal.psbt();
  }

  T _wrapSync<T>(T Function() fn, String step) {
    try {
      return fn();
    } catch (e) {
      throw RecoverableError('$step failed: $e');
    }
  }

  Future<PayjoinRelayResponse> _postViaRelay(
    pj.RequestResponse Function(String relay) buildRequest, {
    required DateTime deadline,
  }) async {
    var consecutiveFailures = 0;
    while (true) {
      if (_cancelled) throw CancelException();
      if (DateTime.now().isAfter(deadline)) {
        throw RecoverableError(
            'Payjoin receiver session expired before relay connectivity returned');
      }
      // Stateless relay choice: every pick is random over the full
      // configured pool. A broken relay costs one wasted request per
      // round; the next pick naturally spreads load across the pool.
      // Retries are bounded by [deadline], not by failure marks.
      final relay = _mailroomManager.chooseRelay();
      // FFI/protocol errors raised while building the request are NOT relay
      // problems — propagate them so the caller sees the real cause.
      final reqResp = buildRequest(relay);
      try {
        final response = await client
            .post(
              Uri.parse(reqResp.request.url),
              headers: {'Content-Type': reqResp.request.contentType},
              body: reqResp.request.body,
            )
            .timeout(_relayRequestTimeout,
                onTimeout: () => throw SocketException(
                    'relay $relay request timed out'));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return PayjoinRelayResponse(
            bodyBytes: response.bodyBytes,
            ohttpCtx: reqResp.clientResponse,
            requestUrl: reqResp.request.url,
          );
        }
        // Non-2xx from the relay itself (OHTTP wraps the directory response,
        // so the relay's status is its own) — try again.
        printV('[pjReceiver] relay $relay returned HTTP ${response.statusCode}');
      } on IOException catch (e) {
        // Transport failure of any kind — socket, TLS handshake, HTTP
        // protocol, request timeout. Try the next pick. A cancel disposes
        // the HTTP client mid-request, surfacing as one of these — exit
        // as a cancellation instead.
        if (_cancelled) throw CancelException();
        printV('[pjReceiver] relay $relay transport error: $e');
      } on http.ClientException catch (e) {
        if (_cancelled) throw CancelException();
        printV('[pjReceiver] relay $relay transport error: $e');
      }
      await Future.delayed(_nextBackoff(consecutiveFailures++));
    }
  }
}

Duration _nextBackoff(int consecutiveFailures) {
  if (consecutiveFailures == 0) return _initialBackoff;
  final seconds = (_initialBackoff.inSeconds * (1 << consecutiveFailures))
      .clamp(_initialBackoff.inSeconds, _maxBackoff.inSeconds);
  return Duration(seconds: seconds);
}

class CancelException extends PayjoinSessionError {
  const CancelException() : super('Payjoin receiver session cancelled');
}

class _InMemoryReceiverPersister extends pj.JsonReceiverSessionPersister {
  final List<String> _events = [];

  @override
  void save(String event) => _events.add(event);

  @override
  List<String> load() => List.from(_events);

  @override
  void close() => _events.clear();
}
