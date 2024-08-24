import 'dart:typed_data';

import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/receive/v2.dart' as v2;
import 'package:payjoin_flutter/uri.dart' as pj_uri;
import 'package:http/http.dart' as http;
import 'package:payjoin_flutter/src/generated/utils/types.dart' as types;

import 'electrum_wallet.dart';

export 'package:payjoin_flutter/receive/v2.dart'
    show ActiveSession, UncheckedProposal, PayjoinProposal;

export 'package:payjoin_flutter/send.dart' show RequestContext;

export 'package:payjoin_flutter/src/exceptions.dart' show PayjoinException;

class BitcoinPayjoin {
  // Private constructor
  BitcoinPayjoin._internal();

  // Singleton instance
  static final BitcoinPayjoin _instance = BitcoinPayjoin._internal();

  // Factory constructor to return the singleton instance
  factory BitcoinPayjoin() {
    return _instance;
  }

  static const pjUrl = "https://payjo.in";
  static const ohttpRelay = "https://pj.bobspacebkk.com";
  static const payjoinDirectory = "https://payjo.in";
  static const v2ContentType = "message/ohttp-req";

  Network get testnet => Network.testnet;
  Network get mainnet => Network.bitcoin;

  Future<Map<String, dynamic>> buildV2PjStr({
    int? amount,
    required String address,
    required Network network,
    required int expireAfter,
  }) async {
    // Start a Payjoin receive session with the given parameters
    final session = await _startV2ReceiveSession(
      address: address,
      network: network,
      expireAfter: expireAfter,
    );

    // Get the Payjoin URI builder from the session
    final pjUriBuilder = session.pjUriBuilder();
    // Build the URI
    final pjUri = pjUriBuilder.build();
    final pjUriStr = pjUri.asString();

    return {'pjUri': pjUriStr, 'session': session};
  }

  Future<v2.ActiveSession> _startV2ReceiveSession({
    required String address,
    required Network network,
    required int expireAfter,
  }) async {
    // Convert the OHTTP relay URL string to a Url object
    final ohttpRelayUrl = await pj_uri.Url.fromStr(ohttpRelay);
    // Convert the Payjoin directory URL string to a Url object
    final payjoinDirectoryUrl = await pj_uri.Url.fromStr(payjoinDirectory);

    // Fetch OHTTP keys using the relay and directory URLs
    pj_uri.OhttpKeys ohttpKeys = await pj_uri.fetchOhttpKeys(
      ohttpRelay: ohttpRelayUrl,
      payjoinDirectory: payjoinDirectoryUrl,
    );

    // Initialize a Payjoin session with the provided parameters
    final session = await v2.SessionInitializer.create(
      address: address,
      ohttpRelay: ohttpRelayUrl,
      directory: payjoinDirectoryUrl,
      ohttpKeys: ohttpKeys,
      network: network,
      expireAfter: BigInt.from(expireAfter),
    );

    // Extract the Payjoin request and context from the session
    final extractReq = await session.extractReq();

    // Send the Payjoin request to the server using HTTP POST
    final response = await http.post(
      Uri.parse(extractReq.$1.url.asString()),
      body: extractReq.$1.body,
      headers: {
        'Content-Type': v2ContentType,
      },
    );

    // Process the server's response to activate the Payjoin session
    final activeSession = await session.processRes(
      body: response.bodyBytes,
      ctx: extractReq.$2,
    );

    return activeSession;
  }

  Future<v2.UncheckedProposal> pollV2Request(v2.ActiveSession session) async {
    // Start an infinite loop to continuously poll for requests
    while (true) {
      try {
        // Extract the request and context from the session. This may also throw a timeout error.
        final extractReq = await session.extractReq();

        // Send the extracted request to the server using HTTP POST
        final originalPsbt = await http.post(
          Uri.parse(extractReq.$1.url.asString()),
          body: extractReq.$1.body,
          headers: {
            'Content-Type': v2ContentType,
          },
        );

        // Process the server's response to get an unchecked proposal
        final uncheckedProposal = await session.processRes(
          body: originalPsbt.bodyBytes,
          ctx: extractReq.$2,
        );

        // If a valid unchecked proposal is received, return it and end the loop
        if (uncheckedProposal != null) {
          return uncheckedProposal;
        }

        // Wait for 2 seconds before retrying to avoid overloading the server
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        // If an error occurs (like a timeout), rethrow the error to be handled by the caller
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> handleV2Request({
    required v2.UncheckedProposal uncheckedProposal,
    required Object receiverWallet,
  }) async {
    // Call the _handleV2Request function to process the unchecked proposal and
    //get the original transaction and a Payjoin proposal
    final request = await _handleV2Request(
      proposal: uncheckedProposal,
      receiverWallet: receiverWallet,
    );

    final originalTx = request['originalTx'];
    final payjoinProposal = request['payjoinProposal'] as v2.PayjoinProposal;

    final extractReq = await payjoinProposal.extractV2Req();

    // Send the extracted V2 request to the server
    final res = await http.post(
      Uri.parse(extractReq.$1.url.asString()),
      body: extractReq.$1.body,
      headers: {
        'Content-Type': v2ContentType,
      },
    );

    // Process the server's response to update the Payjoin proposal with the result
    await payjoinProposal.processRes(
      res: res.bodyBytes,
      ohttpContext: extractReq.$2,
    );

    return {'originalTx': originalTx, 'payjoinProposal': payjoinProposal};
  }

  Future<Map<String, dynamic>> _handleV2Request({
    required v2.UncheckedProposal proposal,
    required Object receiverWallet,
  }) async {
    final bitcoinWallet = receiverWallet as ElectrumWallet;
    try {
      // Extract the transaction bytes from the proposal to schedule it for broadcasting
      final originalTxBytes = await proposal.extractTxToScheduleBroadcast();

      // TODO: Convert the extracted bytes into a Bitcoin Transaction object
      final originalTx =
          await bdk.Transaction.fromBytes(transactionBytes: originalTxBytes);

      // Check the suitability of the proposal for broadcasting
      final ownedInputs =
          await proposal.checkBroadcastSuitability(canBroadcast: (e) async {
        return true; // Assume the transaction is suitable for broadcasting
      });

      // Ensure no mixed input scripts (i.e., inputs not owned by the wallet)
      final mixedInputScripts = await ownedInputs.checkInputsNotOwned(
          isOwned: (i) => _isOwned(i, receiverWallet));

      // Check that no previously seen inputs are being reused in the transaction
      final seenInputs = await mixedInputScripts.checkNoMixedInputScripts();

      // Identify which outputs belong to the receiver's wallet
      final payjoin =
          await (await seenInputs.checkNoInputsSeenBefore(isKnown: (e) async {
        return false; // Assume no inputs have been seen before
      }))
              .identifyReceiverOutputs(
        isReceiverOutput: (i) => _isOwned(i, receiverWallet),
      );

      // TODO: List all unspent outputs (UTXOs) available in the receiver's wallet
      // final availableInputs = receiverWallet.listUnspent();
      final availableInputs = bitcoinWallet.unspentCoins;

      // Create a map of candidate inputs with their corresponding outpoints
      Map<BigInt, types.OutPoint> candidateInputs = {
        for (var input in availableInputs)
          BigInt.from(input.value): types.OutPoint(
            txid: input.hash.toString(),
            vout: input.vout,
          )
      };

      // Try to select an outpoint that preserves the privacy of the transaction
      final selectedOutpoint = await payjoin.tryPreservingPrivacy(
        candidateInputs: candidateInputs,
      );

      // Find the selected UTXO from the available inputs
      var selectedUtxo = availableInputs.firstWhere(
          (i) =>
              i.hash == selectedOutpoint.txid &&
              i.vout == selectedOutpoint.vout,
          // (i) =>
          //     i.outpoint.txid == selectedOutpoint.txid &&
          //     i.outpoint.vout == selectedOutpoint.vout,
          orElse: () => throw Exception('UTXO not found'));

      // Create a TxOut object representing the selected UTXO's output
      var txoToContribute = types.TxOut(
        value: BigInt.from(selectedUtxo.value),
        scriptPubkey: selectedUtxo.txout.scriptPubkey.bytes,
      );

      // Create an OutPoint object representing the selected UTXO's outpoint
      var outpointToContribute = types.OutPoint(
        txid: selectedUtxo.hash.toString(),
        vout: selectedUtxo.vout,
      );

      // Contribute the selected witness input to the Payjoin transaction
      await payjoin.contributeWitnessInput(
        txo: txoToContribute,
        outpoint: outpointToContribute,
      );

      // Finalize the Payjoin proposal by processing the PSBT (Partially Signed Bitcoin Transaction)
      final payjoinProposal = await payjoin.finalizeProposal(
          processPsbt: (i) => _processPsbt(i, receiverWallet));

      // Return the original transaction and the finalized Payjoin proposal
      return {'originalTx': originalTx, 'payjoinProposal': payjoinProposal};
    } on Exception catch (e) {
      // If an error occurs, log the error and rethrow it
      print('[!] bitcoin_payjoin.dart || _handleV2Request() => e: $e');
      rethrow;
    }
  }

  Future<bool> _isOwned(Uint8List bytes, Object wallet) async {
    // TODO: Create a ScriptBuf object from the provided byte data
    // Eg: final script = bdk.ScriptBuf(bytes: bytes);

    // TODO: Check if the wallet recognizes the script as one of its own
    // Eg: return wallet.isMine(script: script);
  }

  Future<String> _processPsbt(String preProcessed, Object wallet) async {
    // TODO: Convert the provided string representation of a PSBT into a PartiallySignedTransaction object
    final psbt = await bdk.PartiallySignedTransaction.fromString(preProcessed);

    // TODO: Sign the PSBT using the wallet's private keys with specified signing options
    await wallet.sign(
      psbt: psbt,
      signOptions: const bdk.SignOptions(
        trustWitnessUtxo: true,
        allowAllSighashes: false,
        removePartialSigs: true,
        tryFinalize: true,
        signWithTapInternalKey: true,
        allowGrinding: false,
      ),
    );

    // Return the string representation of the signed PSBT
    return psbt.asString();
  }

  Future<String> getTxIdFromPsbt(String psbtBase64) async {
    // Create a PartiallySignedTransaction object from the Base64-encoded PSBT string
    final psbt = await bdk.PartiallySignedTransaction.fromString(psbtBase64);
    // Extract the transaction from the PSBT and get its transaction ID (txid)
    final txId = psbt.extractTx().txid();
    return txId;
  }
}
