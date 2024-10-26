import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/psbt_signer.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/receive/v2.dart' as v2;
import 'package:payjoin_flutter/uri.dart' as pj_uri;
import 'package:http/http.dart' as http;
import 'package:payjoin_flutter/src/generated/utils/types.dart' as types;

import 'package:payjoin_flutter/send.dart' as send;

import 'pending_bitcoin_transaction.dart';

export 'package:payjoin_flutter/receive/v2.dart'
    show ActiveSession, UncheckedProposal, PayjoinProposal;

export 'package:payjoin_flutter/uri.dart' show Uri;

export 'package:payjoin_flutter/send.dart' show RequestContext;

export 'package:payjoin_flutter/src/exceptions.dart' show PayjoinException;

import 'package:ledger_bitcoin/src/psbt/psbt_extractor.dart';

import 'psbt_converter.dart';

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

/*
+-------------------------+
| Receiver starts from here |
+-------------------------+
*/

  Future<Map<String, dynamic>> buildV2PjStr({
    int? amount,
    required String address,
    required Network network,
    required int expireAfter,
  }) async {
    print(
        '[+] BitcoinPayjoin || buildV2PjStr => address: $address \n amount: $amount \n network: $network');
    // Start a Payjoin receive session with the given parameters
    final session = await _startV2ReceiveSession(
      address: address,
      network: network,
      expireAfter: expireAfter,
    );

    String pjUriStr;

    // Get the Payjoin URI builder from the session
    final pjUriBuilder = session.pjUriBuilder();

    // Build the URI
    if (amount != null) {
      final pjUriBuilderWithAmount =
          pjUriBuilder.amount(amount: BigInt.from(amount));
      final pjUri = pjUriBuilderWithAmount.build();
      pjUriStr = pjUri.asString();
    } else {
      final pjUri = pjUriBuilder.build();
      pjUriStr = pjUri.asString();
    }

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

  String getTxIdFromTxBytes(Uint8List txBytes) {
    final originalTx = BtcTransaction.fromRaw(BytesUtils.toHexString(txBytes));
    return originalTx.txId();
  }

  Future<Map<String, dynamic>> _handleV2Request({
    required v2.UncheckedProposal proposal,
    required Object receiverWallet,
  }) async {
    final bitcoinWallet = receiverWallet as ElectrumWallet;
    try {
      // Extract the transaction bytes from the proposal to schedule it for broadcasting
      final originalTxBytes = await proposal.extractTxToScheduleBroadcast();

      // Convert the extracted bytes into a Bitcoin Transaction object
      final originalTx = getTxIdFromTxBytes(originalTxBytes);

      // Check the suitability of the proposal for broadcasting
      final ownedInputs =
          await proposal.checkBroadcastSuitability(canBroadcast: (e) async {
        return true; // Assume the transaction is suitable for broadcasting
      });

      // Ensure no mixed input scripts (i.e., inputs not owned by the wallet)
      final mixedInputScripts = await ownedInputs.checkInputsNotOwned(
          isOwned: (i) => _isOwned(i, bitcoinWallet));

      // Check that no previously seen inputs are being reused in the transaction
      final seenInputs = await mixedInputScripts.checkNoMixedInputScripts();

      // Identify which outputs belong to the receiver's wallet
      final payjoin =
          await (await seenInputs.checkNoInputsSeenBefore(isKnown: (e) async {
        return false; // Assume no inputs have been seen before
      }))
              .identifyReceiverOutputs(
        isReceiverOutput: (i) => _isOwned(i, bitcoinWallet),
      );

      // TODO: List all unspent outputs (UTXOs) available in the receiver's wallet
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
          orElse: () => throw Exception('UTXO not found'));

      // Create a TxOut object representing the selected UTXO's output
      var scriptList = P2trAddress.fromAddress(
        address: selectedUtxo.address,
        network: bitcoinWallet.network,
      ).toScriptPubKey().script as List<int>;

      var txoToContribute = types.TxOut(
        value: BigInt.from(selectedUtxo.value),
        scriptPubkey: Uint8List.fromList(scriptList),
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
          processPsbt: (i) => _processPsbt(i, bitcoinWallet));

      // Return the original transaction and the finalized Payjoin proposal
      return {'originalTx': originalTx, 'payjoinProposal': payjoinProposal};
    } on Exception catch (e) {
      // If an error occurs, log the error and rethrow it
      print('[!] bitcoin_payjoin.dart || _handleV2Request() => e: $e');
      rethrow;
    }
  }

  Future<bool> _isOwned(Uint8List bytes, ElectrumWallet wallet) async {
    // Create a ScriptBuf object from the provided byte data
    print('[+] BitcoinPayjoin || _isOwned');
    final script = Script(script: bytes);

    final isMine = wallet.isMine(script);
    print('[+] BitcoinPayjoin || _isOwned => isMine: $isMine');

    return isMine;
  }

  Future<String> _processPsbt(
      String preProcessed, ElectrumWallet wallet) async {
    final signedPsbt = wallet.signPsbt(preProcessed);

    // Return the string representation of the signed PSBT
    return signedPsbt;
  }

  Future<String> getTxIdFromPsbt(String psbtBase64) async {
    final psbt = PsbtV2()..deserialize(base64.decode(psbtBase64));
    final doubleSha256 = QuickCrypto.sha256DoubleHash(psbt.extract());
    final revert = Uint8List.fromList(doubleSha256);
    final txId = hex.encode(revert.reversed.toList());
    return txId;
  }

/*
+-------------------------+
| Sender starts from here |
+-------------------------+
*/

  Future<pj_uri.Uri?> stringToPjUri(String pj) async {
    try {
      return await pj_uri.Uri.fromStr(pj);
    } catch (e) {
      print('[!] BitcoinPayjoin || stringToPjUri() => e: $e');
      return null;
    }
  }

  Future<String> buildOriginalPsbt(
    Object wallet,
    dynamic pjUri,
    int fee,
    double amount,
    bool isTestnet,
    Object credentials,
  ) async {
    final uri = pjUri as pj_uri.Uri;
    final bitcoinWallet = wallet as ElectrumWallet;

    // final tx = await bitcoinWallet.createPayjoinTransaction(
    //   credentials,
    //   pjBtcAddress: uri.address(),
    // );

    final psbtv0 = await bitcoinWallet.createPayjoinTransaction(
      credentials,
      pjBtcAddress: uri.address(),
    );

    return base64Encode(psbtv0);
  }

  Future<send.RequestContext> buildPayjoinRequest(
    String originalPsbt,
    dynamic pjUri,
    int fee,
  ) async {
    final uri = pjUri as pj_uri.Uri;

    // Create a RequestBuilder from the given original PSBT and Payjoin URI
    // The Payjoin URI is checked for Payjoin support before proceeding
    final requestBuilder = await send.RequestBuilder.fromPsbtAndUri(
      psbtBase64: originalPsbt,
      pjUri: uri.checkPjSupported(),
    );

    // Build a RequestContext using the RequestBuilder with a minimum fee rate
    // Here, a minimum fee rate of 1 satoshi per byte is set
    final requestContext = await requestBuilder.buildRecommended(
      minFeeRate: BigInt.from(1),
    );

    return requestContext;
  }

  Future<String> requestAndPollV2Proposal(
    send.RequestContext requestContext,
  ) async {
    // Keep polling for a V2 proposal
    while (true) {
      try {
        // Extract the V2 request and context using the requestContext
        // The extraction includes specifying the OHTTP proxy URL for Payjoin
        final extractV2 = await requestContext.extractV2(
          ohttpProxyUrl: await pj_uri.Url.fromStr(payjoinDirectory),
        );

        // Post the extracted request to the server
        final response = await http.post(
          Uri.parse(extractV2.$1.url.asString()),
          headers: {
            'Content-Type': v2ContentType,
          },
          body: extractV2.$1.body,
        );

        // Process the response from the server using the context
        final checkedPayjoinProposal =
            await extractV2.$2.processResponse(response: response.bodyBytes);

        // If a valid Payjoin proposal is received, return it
        if (checkedPayjoinProposal != null) {
          return checkedPayjoinProposal;
        }

        // Add a 2-second delay before the next polling attempt
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        // If the session times out or another error occurs, rethrow the error
        rethrow;
      }
    }
  }

  Future<PendingBitcoinTransaction> extractPjTx(
    Object wallet,
    String psbtString,
    Object credentials,
  ) async {
    final bitcoinWallet = wallet as ElectrumWallet;

    final pendingTx =
        await bitcoinWallet.psbtToPendingTx(psbtString, credentials);

    return pendingTx;
  }
}
