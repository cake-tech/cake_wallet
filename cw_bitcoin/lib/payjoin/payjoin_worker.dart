import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cw_bitcoin/psbt_signer.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:payjoin_flutter/bitcoin_ffi.dart';
import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/src/generated/frb_generated.dart' as pj;
import 'package:payjoin_flutter/receive.dart';


enum PayjoinReceiverRequestTypes {
  proposalSent,
  getCandidateInputs,
  checkIsOwned,
  checkIsReceiverOutput,
  processPsbt;
}

class PayjoinSessionError {
  final String message;

  const PayjoinSessionError._(this.message);

  factory PayjoinSessionError.recoverable(String message) = RecoverableError;
  factory PayjoinSessionError.unrecoverable(String message) = UnrecoverableError;
}

class RecoverableError extends PayjoinSessionError {
  const RecoverableError(super.message) : super._();
}

class UnrecoverableError extends PayjoinSessionError {
  const UnrecoverableError(super.message) : super._();
}

class PayjoinReceiverWorker {
  final SendPort sendPort;
  final pendingRequests = <String, Completer<dynamic>>{};

  PayjoinReceiverWorker._(this.sendPort);

  static Future<void> run(List<Object> args) async {
    await pj.core.init();

    final sendPort = args[0] as SendPort;
    final receiverJson = args[1] as String;

    final worker = PayjoinReceiverWorker._(sendPort);
    final receivePort = ReceivePort();

    sendPort.send(receivePort.sendPort);
    receivePort.listen(worker.handleMessage);


    try {
      final httpClient = HttpClient();
      final receiver = Receiver.fromJson(receiverJson);

      final uncheckedProposal = await worker.receiveUncheckedProposal(httpClient, receiver);
      final payjoinProposal = await worker.processPayjoinProposal(
        uncheckedProposal,
      );
      await worker.sendFinalProposal(httpClient, payjoinProposal);
      sendPort.send({'type': PayjoinReceiverRequestTypes.proposalSent});
    } catch (e) {
      if (e is HttpException) {
        sendPort.send(PayjoinSessionError.recoverable(e.toString()));
      } else {
        sendPort.send(PayjoinSessionError.unrecoverable(e.toString()));
      }
    }
  }

  void handleMessage(dynamic message) async {
    if (message is Map<String, dynamic>) {
      final requestId = message['requestId'] as String?;
      if (requestId != null && pendingRequests.containsKey(requestId)) {
        pendingRequests[requestId]!.complete(message['result']);
        pendingRequests.remove(requestId);
      }
    }
  }

  Future<dynamic> _sendRequest(PayjoinReceiverRequestTypes type, [Map<String, dynamic> data = const {}])async {
    final completer = Completer<dynamic>();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    pendingRequests[requestId] = completer;

    sendPort.send({
      ...data,
      'type': type,
      'requestId': requestId,
    });

    return completer.future;
  }

  Future<UncheckedProposal> receiveUncheckedProposal(HttpClient httpClient, Receiver session) async {
    UncheckedProposal? proposal;
    while (proposal == null) {
      final extractReq = await session.extractReq();
      final request = extractReq.$1;
      final clientResponse = extractReq.$2;

      final url = Uri.parse(request.url.asString());
      final httpRequest = await httpClient.postUrl(url);
      httpRequest.headers.set('Content-Type', request.contentType);
      httpRequest.add(request.body);

      final response = await httpRequest.close();
      final responseBody = await response.fold<List<int>>(
          [], (previous, element) => previous..addAll(element));
      final uint8Response = Uint8List.fromList(responseBody);
      proposal =
          await session.processRes(body: uint8Response, ctx: clientResponse);
    }

    return proposal;
  }

  Future<void> sendFinalProposal(HttpClient httpClient, PayjoinProposal finalProposal) async {
    final req = await finalProposal.extractV2Req();
    final proposalReq = req.$1;
    final proposalCtx = req.$2;

    final httpRequest = await httpClient.postUrl(
      Uri.parse(proposalReq.url.asString()),
    );
    httpRequest.headers.set('content-type', 'message/ohttp-req');
    httpRequest.add(proposalReq.body);

    final response = await httpRequest.close();
    final responseBody = await response.fold<List<int>>(
      [],
          (previous, element) => previous..addAll(element),
    );
    await finalProposal.processRes(
        res: responseBody, ohttpContext: proposalCtx);

    final ps = await finalProposal.psbt();
    printV(ps);
  }

  Future<PayjoinProposal> processPayjoinProposal(UncheckedProposal proposal) async {
    await proposal.extractTxToScheduleBroadcast();
    // TODO Handle this. send to the main port on a timer?

    try {
      // Receive Check 1: can broadcast
      final pj1 = await proposal.assumeInteractiveReceiver();

      // Receive Check 2: original PSBT has no receiver-owned inputs
      final pj2 = await pj1.checkInputsNotOwned(
        isOwned: (inputScript) async {
          final result = await _sendRequest(
            PayjoinReceiverRequestTypes.checkIsOwned,
            {'input_script': inputScript},
          );
          return result as bool;
        },
      );
      // Receive Check 3: sender inputs have not been seen before (prevent probing attacks)
      final pj3 = await pj2.checkNoInputsSeenBefore(isKnown: (input) => false);

      // Identify receiver outputs
      final pj4 = await pj3.identifyReceiverOutputs(
        isReceiverOutput: (outputScript) async {
          final result = await _sendRequest(
            PayjoinReceiverRequestTypes.checkIsReceiverOutput,
            {'output_script': outputScript},
          );
          return result as bool;
        },
      );
      final pj5 = await pj4.commitOutputs();

      final listUnspent = await _sendRequest(PayjoinReceiverRequestTypes.getCandidateInputs);
      final unspent = listUnspent as List<UtxoWithPrivateKey>;
      if (unspent.isEmpty) throw Exception('No unspent outputs available');

      final selectedUtxo = await _inputPairFromUtxo(unspent[0]);
      final pj6 = await pj5.contributeInputs(replacementInputs: [selectedUtxo]);
      final pj7 = await pj6.commitInputs();

      // Finalize proposal
      final payjoinProposal = await pj7.finalizeProposal(
        processPsbt: (String psbt) async {
          final result = await _sendRequest(
            PayjoinReceiverRequestTypes.processPsbt,
            {'psbt': psbt}
          );
          return result as String;
        },
        // TODO set maxFeeRateSatPerVb
        maxFeeRateSatPerVb: BigInt.from(10000),
      );
      return payjoinProposal;
    } catch (e) {
      print('Error occurred while finalizing proposal: $e');
      rethrow;
    }
  }

  Future<InputPair> _inputPairFromUtxo(UtxoWithPrivateKey utxo) async {
    final txout = TxOut(
      value: utxo.utxo.value,
      scriptPubkey: Uint8List.fromList(
          utxo.ownerDetails.address.toScriptPubKey().toBytes()),
    );

    final psbtin =
        PsbtInput(witnessUtxo: txout, redeemScript: null, witnessScript: null);

    final previousOutput =
        OutPoint(txid: utxo.utxo.txHash, vout: utxo.utxo.vout);

    final txin = TxIn(
      previousOutput: previousOutput,
      scriptSig: await Script.newInstance(rawOutputScript: []),
      witness: [],
      sequence: 0,
    );

    return InputPair.newInstance(txin, psbtin);
  }
}
