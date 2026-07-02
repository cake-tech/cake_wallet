import 'dart:convert';
import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/payjoin/payjoin_signer.dart';
import 'package:cw_bitcoin/psbt/signer.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:payjoin/payjoin.dart' as pj;

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

class _ProcessPsbt extends pj.ProcessPsbt {
  final String Function(String) fn;
  _ProcessPsbt(this.fn);
  @override
  String callback(String psbt) => fn(psbt);
}

class PayjoinReceiverWorker {
  final String ohttpRelay;
  final http.Client client = ProxyWrapper().getHttpIOClient();
  final List<UtxoWithPrivateKey> utxos;
  final bool Function(Uint8List) isMineChecker;
  final int Function()? getCurrentHeight;
  final pj.JsonReceiverSessionPersister? _persister;
  bool _cancelled = false;

  PayjoinReceiverWorker({
    required this.ohttpRelay,
    required this.utxos,
    required this.isMineChecker,
    this.getCurrentHeight,
    pj.JsonReceiverSessionPersister? persister,
  }) : _persister = persister;

  void cancel() => _cancelled = true;

  Future<String> run(String address, String directory, pj.OhttpKeys ohttpKeys) async {
    try {
      if (_cancelled) throw CancelException();
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
      final maybeInputsOwned = state.inner.assumeInteractiveReceiver().save(persister: persister);
      return _processFromMaybeInputsOwned(maybeInputsOwned, persister);
    }
    if (state is pj.ClosedReceiveSession) {
      throw Exception('Session already completed');
    }
    // Terminal error states
    throw Exception('Session not resumable: ${state.runtimeType}');
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
    final maybeInputsOwned =
        uncheckedProposal.assumeInteractiveReceiver().save(persister: persister);

    return _processFromMaybeInputsOwned(maybeInputsOwned, persister);
  }

  Future<String> _processFromMaybeInputsOwned(
    pj.MaybeInputsOwned maybeInputsOwned,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    final payjoinProposal = await _processPayjoinProposal(maybeInputsOwned, persister);
    // Log the PSBT that will be sent to the sender
    final psbtToSend = payjoinProposal.psbt();
    printV('=== PayjoinProposal PSBT (sent to sender) ===');
    printV(psbtToSend);
    // Decode first 300 chars of base64 to hex for manual inspection
    final decoded = base64Decode(psbtToSend);
    printV(
        'First 300 bytes hex: ${BytesUtils.toHexString(decoded.sublist(0, decoded.length > 300 ? 300 : decoded.length))}');
    return _sendFinalProposal(payjoinProposal, persister);
  }

  Future<pj.UncheckedOriginalPayload> _pollForProposal(
    pj.Initialized initialized,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    while (true) {
      if (_cancelled) throw CancelException();
      printV('Polling for Proposal');
      try {
        final reqResp = initialized.createPollRequest(ohttpRelay: ohttpRelay);
        final httpResponse = await client.post(
          Uri.parse(reqResp.request.url),
          headers: {'Content-Type': reqResp.request.contentType},
          body: reqResp.request.body,
        );
        final transition = initialized.processResponse(
          body: httpResponse.bodyBytes,
          ctx: reqResp.clientResponse,
        );
        final outcome = transition.save(persister: persister);

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
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<pj.PayjoinProposal> _processPayjoinProposal(
    pj.MaybeInputsOwned maybeInputsOwned,
    pj.JsonReceiverSessionPersister persister,
  ) async {
    try {
      final checkOwned = await maybeInputsOwned.checkInputsNotOwned(
        isOwned: _IsScriptOwned(isMineChecker),
      );
      final maybeInputsSeen = checkOwned.save(persister: persister);

      final checkSeen = await maybeInputsSeen.checkNoInputsSeenBefore(
        isKnown: _IsOutputKnown((_) => false),
      );
      final outputsUnknown = checkSeen.save(persister: persister);

      final identifyOutputs = await outputsUnknown.identifyReceiverOutputs(
        isReceiverOutput: _IsScriptOwned(isMineChecker),
      );
      final wantsOutputs = identifyOutputs.save(persister: persister);

      final wantsOutputsTransition = wantsOutputs.commitOutputs();
      var wantsInputs = wantsOutputsTransition.save(persister: persister);

      final candidateInputs = _buildInputPairs();

      if (candidateInputs.isEmpty) {
        throw RecoverableError('No unspent outputs available');
      }

      pj.InputPair selectedUtxo = candidateInputs.first;
      try {
        selectedUtxo = wantsInputs.tryPreservingPrivacy(
          candidateInputs: candidateInputs,
        );
      } catch (_) {}

      wantsInputs = wantsInputs.contributeInputs(replacementInputs: [selectedUtxo]);
      final commitInputsTransition = wantsInputs.commitInputs();
      final wantsFeeRange = commitInputsTransition.save(persister: persister);

      final applyFeeRangeTransition = wantsFeeRange.applyFeeRange(
        minFeeRateSatPerVb: null,
        maxEffectiveFeeRateSatPerVb: 10000,
      );
      final provisionalProposal = applyFeeRangeTransition.save(persister: persister);

      // Log the PSBT before our signing (from psbt_to_sign)
      final psbtToSignStr = provisionalProposal.psbtToSign();
      printV('=== PSBT to sign (before receiver signing) ===');
      printV(psbtToSignStr);
      final decodedToSign = base64Decode(psbtToSignStr);
      printV(
          'First 300 bytes hex: ${BytesUtils.toHexString(decodedToSign.sublist(0, decodedToSign.length > 300 ? 300 : decodedToSign.length))}');

      final finalizeTransition = provisionalProposal.finalizeProposal(
        processPsbt: _ProcessPsbt(
          (psbt) => signPsbtSync(psbt, utxos),
        ),
      );
      return finalizeTransition.save(persister: persister);
    } catch (e) {
      printV('Error processing payjoin proposal: $e');
      rethrow;
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
    final reqResp = proposal.createPostRequest(ohttpRelay: ohttpRelay);
    final httpResponse = await client.post(
      Uri.parse(reqResp.request.url),
      headers: {'Content-Type': reqResp.request.contentType},
      body: reqResp.request.body,
    );
    final transition = proposal.processResponse(
      body: httpResponse.bodyBytes,
      ohttpContext: reqResp.clientResponse,
    );
    transition.save(persister: persister);
    return proposal.psbt();
  }
}

class CancelException implements Exception {}

class RecoverableError implements Exception {
  final String message;
  RecoverableError(this.message);
  @override
  String toString() => message;
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
